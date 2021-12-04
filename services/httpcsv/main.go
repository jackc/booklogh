package main

import (
	"bytes"
	"context"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
)

var db *pgxpool.Pool

func main() {
	var err error
	db, err = pgxpool.Connect(context.Background(), "")
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/books/export", ExportHandler)
	http.HandleFunc("/books/import_csv", ImportHandler)
	http.ListenAndServe(fmt.Sprintf(":%s", os.Args[1]), nil)
}

type Session struct {
	UserID int32 `json:"userId"`
}

func ExportHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var session Session
	err := json.Unmarshal([]byte(r.Header.Get("X-Hannibal-Cookie-Session")), &session)
	if err != nil {
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	buf := &bytes.Buffer{}
	csvWriter := csv.NewWriter(buf)
	csvWriter.Write([]string{"title", "author", "finish_date", "format"})

	var title, author, format string
	var finishDate time.Time
	_, err = db.QueryFunc(ctx, `select title, author, finish_date, format
from books
where user_id=$1
order by finish_date desc`,
		[]interface{}{session.UserID},
		[]interface{}{&title, &author, &finishDate, &format},
		func(qfr pgx.QueryFuncRow) error {
			return csvWriter.Write([]string{title, author, finishDate.Format("2006-01-02"), format})
		})
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		log.Println(err)
		return
	}

	csvWriter.Flush()
	if csvWriter.Error() != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		log.Println(csvWriter.Error())
		return
	}

	w.Header().Set("Content-Type", "text/csv")
	w.Header().Set("Content-Disposition", "attachment; filename=books.csv")
	_, err = buf.WriteTo(w)
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		log.Println(err)
		return
	}
}

func ImportHandler(w http.ResponseWriter, r *http.Request) {
	// ctx := r.Context()

	r.ParseMultipartForm(10 << 20)
	file, _, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		log.Println(err)
		return
	}
	defer file.Close()

	records, err := csv.NewReader(file).ReadAll()
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		log.Println(err)
		return
	}

	for _, record := range records {
		fmt.Println(record)
	}
}

// func CookieSessionHandler(w http.ResponseWriter, r *http.Request) {
// 	switch r.Method {
// 	case http.MethodGet:
// 		w.Write([]byte(r.Header.Get("X-Hannibal-Cookie-Session")))
// 		return
// 	case http.MethodPost:
// 		body, err := ioutil.ReadAll(r.Body)
// 		if err != nil {
// 			w.WriteHeader(http.StatusInternalServerError)
// 			fmt.Fprintf(w, "failed to read request body: %v", err)
// 			return
// 		}
// 		w.Header().Set("X-Hannibal-Cookie-Session", string(body))
// 	default:
// 		w.WriteHeader(http.StatusMethodNotAllowed)
// 		return
// 	}
// }

package main

import (
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
)

func main() {

	dstURL, err := url.Parse("http://127.0.0.1:3001")
	if err != nil {
		log.Fatal(err)
	}
	handler := httputil.NewSingleHostReverseProxy(dstURL)
	http.Handle("/", handler)
	http.ListenAndServe(fmt.Sprintf(":%s", os.Args[1]), nil)
}

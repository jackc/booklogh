create function http_user_home(
  args jsonb,
  inout cookie_session jsonb,
  out status smallint,
  out response_headers jsonb,
  out template text,
  out template_data jsonb
)
language plpgsql as $$
declare
  _current_user users;
begin
  {{ template "require_current_user.sql" . }}

  if _current_user.username <> args ->> 'username' then
    status := 303;
    response_headers := jsonb_build_object('Location', '/');
    return;
  end if;


  template := 'user_home.html';
  template_data := jsonb_build_object(
    'currentUser', jsonb_build_object('id', _current_user.id, 'username', _current_user.username),
    'booksPerYear', (
      select jsonb_agg(t order by t.year desc)
      from (
        select extract('year' from finish_date) as year, count(*) as count
        from books
        where user_id = _current_user.id
        group by 1
      ) t
    ),
    'booksPerMonth', (
      select jsonb_agg(t order by t.month desc)
      from (
        select months::date as month, count(books.id) as count
        from generate_series(date_trunc('month', now() - '1 year'::interval), date_trunc('month', now()), '1 month') as months
          left join books on date_trunc('month', finish_date) = months and user_id = _current_user.id
        group by 1
      ) t
    ),
    'booksByYear', (
      with t as (
        select
          extract('year' from finish_date) as year,
          jsonb_agg(
            jsonb_build_object(
              'id', id,
              'title', title,
              'author', author,
              'finishDate', finish_date,
              'format', format,
              'location', location
            )
            order by finish_date desc
          ) as books
        from books
        where user_id = _current_user.id
        group by 1
      )
      select jsonb_agg(
        jsonb_build_object(
          'year', year,
          'books', books
        )
        order by year desc
      )
      from t
    )
  );
end;
$$;

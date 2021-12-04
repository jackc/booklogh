create function http_book_confirm_delete(
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
  _book books;
begin
  {{ template "require_current_user.sql" . }}

  select *
  into strict _book
  from books
  where id = (args ->> 'id')::int
    and user_id = _current_user.id;

  template := 'book_confirm_delete.html';
  template_data := jsonb_build_object(
    'currentUser', jsonb_build_object('id', _current_user.id, 'username', _current_user.username),
    'book', jsonb_build_object(
      'id', _book.id,
      'title', _book.title,
      'author', _book.author,
      'finishDate', _book.finish_date,
      'format', _book.format,
      'location', _book.location
    )
  );
end;
$$;

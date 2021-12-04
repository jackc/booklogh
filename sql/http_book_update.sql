create function http_book_update(
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

  if args -> '__errors__' is not null then
    template := 'book_edit.html';
    template_data := jsonb_build_object(
      'currentUser', jsonb_build_object('id', _current_user.id, 'username', _current_user.username),
      'book', jsonb_build_object(
        'id', args -> 'id',
        'title', args -> 'title',
        'author', args -> 'author',
        'finishDate', args -> 'finishDate',
        'format', args -> 'format',
        'location', args -> 'location'
      ),
      'errors', args -> '__errors__'
    );

    return;
  end if;

  update books
  set title = (args ->> 'title'),
    author = (args ->> 'author'),
    finish_date = (args ->> 'finishDate')::date,
    format = (args ->> 'format'),
    location = (args ->> 'location')
  where id = (args ->> 'id')::int
    and user_id = _current_user.id;

  if not found then
    status := 404;
    return;
  end if;

  status := 303;
  response_headers := jsonb_build_object('Location', format('/users/%s', _current_user.username));
end;
$$;

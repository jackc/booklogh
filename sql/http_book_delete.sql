create function http_book_delete(
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

  delete from books
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

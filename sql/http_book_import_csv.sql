create function http_book_import_csv(
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

  if args -> '__errors__' is not null then
    template := 'book_import_csv_form.html';
    template_data := jsonb_build_object(
      'currentUser', jsonb_build_object('id', _current_user.id, 'username', _current_user.username),
      'errors', args -> '__errors__'
    );

    return;
  end if;

  raise 'file body: %', convert_from(decode(args -> 'file' ->> 'body', 'base64'), 'UTF8');

end;
$$;

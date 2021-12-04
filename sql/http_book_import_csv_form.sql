create function http_book_import_csv_form(
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

  template := 'book_import_csv_form.html';
  template_data := jsonb_build_object(
    'currentUser', jsonb_build_object('id', _current_user.id, 'username', _current_user.username)
  );
end;
$$;

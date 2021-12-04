create function http_root(
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

  status := 303;
  response_headers := jsonb_build_object('Location', format('/users/%s', _current_user.username));
end;
$$;

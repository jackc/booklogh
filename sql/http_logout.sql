create function http_logout(
  inout cookie_session jsonb,
  out status smallint,
  out response_headers jsonb
)
language plpgsql as $$
begin
  cookie_session := jsonb_build_object();

  status := 303;
  response_headers := jsonb_build_object('Location', '/login');
end;
$$;

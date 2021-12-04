create function http_user_registration_new(
  args jsonb,
  inout cookie_session jsonb,
  out template text,
  out template_data jsonb
)
language plpgsql as $$
begin
  if cookie_session is null then
    cookie_session := jsonb_build_object('visitCount', 0);
  end if;
  cookie_session := jsonb_set(cookie_session, '{visitCount}', to_jsonb((cookie_session ->> 'visitCount')::int + 1));

  select
    'user_registration.html',
    jsonb_build_object(
      'time', now(),
      'name', args ->> 'name',
      'visitCount', cookie_session -> 'visitCount'
    )
  into template, template_data;
end;
$$;

create function http_user_registration(
  args jsonb,
  out status smallint,
  out response_headers jsonb,
  out cookie_session jsonb,
  out template text,
  out template_data jsonb
)
language plpgsql as $$
declare
  _user_id int;
begin
  if args -> '__errors__' is not null then
    template := 'user_registration.html';
    template_data = jsonb_build_object(
      'username', args ->> 'username',
      'errors', args -> '__errors__'
    );
    return;
  end if;

  insert into users (username, password_digest)
  values (args ->> 'username', args ->> 'passwordDigest')
  returning id
  into strict _user_id;

  cookie_session := jsonb_build_object('userId', _user_id);

  status := 303;
  response_headers := jsonb_build_object('Location', '/');
end;
$$;

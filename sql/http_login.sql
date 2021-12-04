create function http_get_login(
  args jsonb,
  out cookie_session jsonb,
  out template text,
  out template_data jsonb
)
language plpgsql as $$
begin
  cookie_session := '{}';

  select
    'login.html',
    jsonb_build_object(
      'time', now(),
      'name', args ->> 'name',
      'visitCount', cookie_session -> 'visitCount'
    )
  into template, template_data;
end;
$$;

create function get_user_password_digest(
  args jsonb
) returns text
language plpgsql as $$
declare
  _password_digest text;
begin
  select password_digest
  into _password_digest
  from users
  where username = args ->> 'username';

  if not found then
    return 'not found';
  end if;

  return _password_digest;
end;
$$;


create function http_post_login(
  args jsonb,
  inout cookie_session jsonb,
  out status smallint,
  out response_headers jsonb,
  out template text,
  out template_data jsonb
)
language plpgsql as $$
declare
  _user_id int;
begin
  if not (args ->> 'validPassword')::boolean then
    template := 'login.html';
    template_data := jsonb_build_object(
      'username', args -> 'username',
      'errors', jsonb_build_object('base', 'bad username or password')
    );
    return;
  end if;

  select id
  into strict _user_id
  from users
  where username = args ->> 'username';

  cookie_session := jsonb_build_object('userId', _user_id);

  status := 303;
  response_headers := jsonb_build_object('Location', '/');
end;
$$;

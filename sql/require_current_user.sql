select id, username into _current_user.id, _current_user.username from users where id = (cookie_session ->> 'userId')::int;
if not found then
  status := 303;
  response_headers := jsonb_build_object('Location', '/login');
  return;
end if;

create table users (
  id int primary key generated by default as identity,
  username text not null unique,
  password_digest text not null,
  insert_time timestamptz not null default now(),
  update_time timestamptz not null default now()
);
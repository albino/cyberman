drop table if exists user;
create table user (
  id integer primary key,
  email text not null,
  password text not null,
  salt text not null,
  active integer not null default 0
);

drop table if exists session;
create table session (
  id integer primary key,
  uid text not null,
  since integer not null,
  token text not null
);

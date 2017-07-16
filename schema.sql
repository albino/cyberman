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
  uid integer not null,
  since integer not null,
  token text not null
);

drop table if exists domain;
create table domain (
  id integer primary key,
  name string not null,
  ownerid integer not null
)

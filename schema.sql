drop table if exists cyberman;
create table cyberman (
	id integer primary key,
	dbrev integer not null
);
insert into cyberman (dbrev) values (4);

drop table if exists user;
create table user (
	id integer primary key,
	email text not null,
	password text not null,
	salt text not null,
	active integer not null default 0,
	conftoken text not null,
	newemail text,
	recoverytoken text
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
	ownerid integer not null,
	lastsid integer not null default 0,
	since integer not null default 1503187200
);

drop table if exists record;
create table record (
	id integer primary key,
	sid integer not null,
	domainid integer not null,
	type string not null,
	name string not null,
	value string not null
);

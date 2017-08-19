create table cyberman (
	id integer primary key,
	dbrev integer not null
);
insert into cyberman (dbrev) values (2);

alter table user add column newemail text;

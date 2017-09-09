alter table cyberman add column intserial integer not null default 1;
alter table cyberman add column lastserial integer not null default 0;
update cyberman set dbrev=7;

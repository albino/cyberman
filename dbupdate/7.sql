alter table cyberman add column zonecheckstatus not null default 0;
update cyberman set dbrev=8;

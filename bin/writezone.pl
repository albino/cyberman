#!/usr/bin/env perl

# Zone writer for cyberman.
# This won't scale well, but it's a basic way to get domains online
# Tested with NSD but should work with your favourite

use strict;
use warnings;
use feature 'say';
use FindBin qw($Bin);
use YAML::Tiny;
use DBI;

my $yml = YAML::Tiny->read("$Bin/../config.yml");
my $tld = $yml->[0]->{"tld"};
my $conf = $yml->[0]->{"zonewriter"};

open my $out, ">", $conf->{"file"} or die $!;

# Introduction
say $out <<'END';
; File produced by cyberman. Do not edit!
$TTL 86400
$ORIGIN cyb.
END

# Write SOA
# Uses mostly hard-coded values for now
say $out "@  1D  IN  SOA $conf->{ns} $conf->{responsible} (";
say $out time;
say $out <<'END';
3H ; refresh
15 ; retry
604800 ; expire
3h ; nxdomain ttl
)
END

if ($conf->{"include"}->{"enabled"}) {
  say $out "\$INCLUDE $conf->{include}->{file}";
}

# Time to get the records
die "Unsupported database!"
  unless $yml->[0]->{"plugins"}->{"Database"}->{"driver"} eq "SQLite";
my $dbfile = "$Bin/../$yml->[0]->{plugins}->{Database}->{dbname}";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

my $sth = $dbh->prepare("SELECT * FROM record");
$sth->execute;

while (my $r = $sth->fetchrow_hashref) {
  # Look up domain
  my $dsth = $dbh->prepare("select * from domain where id=?");
  $dsth->bind_param(1, $r->{"domainid"});
  $dsth->execute;
  my $d = $dsth->fetchrow_hashref;

  # domain name
  if ($r->{"name"} eq '@') {
    print $out $d->{"name"}, " ";
  } else {
    print $out $r->{"name"}, ".", $d->{"name"}, " ";
  }

  # record type
  print $out "IN $r->{type} ";

  # value
  say $out $r->{value};
}

close $out;

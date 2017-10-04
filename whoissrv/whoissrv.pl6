#!/usr/bin/env perl6
use v6.c;
use POSIX;
use YAMLish;
use DBIish;

my $yamldata = slurp "../config.yml";
my $config = load-yaml($yamldata);

my $listener = IO::Socket::Async.listen($config.{'whoissrv'}.{'bind'}, $config.{'whoissrv'}.{'port'});

my $motd = slurp $config.{"whoissrv"}.{"motdfile"};

my $dbh = connect-db();

$listener.tap( -> $conn {
	log("New connection");
	$conn.Supply.tap( -> $in {
		my $q = $in.chomp;
		log "Query: $q";
		await $conn.write: ($motd~"\n").encode("utf-8");

		$q = $q.lc;

		my $tld = $config.{"tld"};
		if ($q !~~ m/\.$tld$/) {
			await $conn.write: "This WHOIS server does not provide data for that TLD.\n".encode("utf-8");
			log("Data not provided; connection closed");
			$conn.close;
			next;
		}
		$q ~~ s/\.$tld$//;
		if ($config.{'reserved_domains'}.Set{$q}) {
			await $conn.write: "$q.$tld is reserved for use by the registry.".encode("utf-8");
			log("Domain reserved");
			$conn.close;
			next;
		}

		my $sth = $dbh.prepare("select * from domain where name = ?");
		$sth.execute($q);
		my $data = $sth.row(:hash);

		$sth = $dbh.prepare("select * from user where id = ?");
		$sth.execute($data.{"ownerid"});
		my $user = $sth.row(:hash);

		if (!$data) {
			await $conn.write: "$q.$tld is not recognised by this WHOIS server.\n".encode("utf-8");
			log("Domain not known; connection closed");
			$conn.close;
			next;
		}

		my $regdate = DateTime.new($data.{"since"});
		my $regurl = $config.{"whoissrv"}.{"registrar-urls"};
		my $email_display = $user.{"email_pub"} == 1 ?? $user.{"email"} !! "< withheld >";
		my $name_display = $user.{"whois_name"} ?? $user.{"whois_name"} !! "< withheld >";

		await $conn.write: qq:heredoc/end/.encode("UTF-8");
		Domain:                 $q.$tld
		Domain Registered:      $regdate
		Domain Updated:         < data currently unavailable >
		Domain Expires:         < data currently unavailable >
		Domain Status:          ACTIVE
		Registrar URL(s):       $regurl

		Registrant Name:        $name_display
		Registrant Email:       $email_display
		end

		$conn.close;
	} );
} );

drop();

await Promise.new;

sub log ($msg) {
	return 1 unless $config.{'whoissrv'}.{'logging'};
	my $stamp = DateTime.now(formatter => { sprintf "[%04d-%02d-%02d %02d:%02d]", .year, .month, .day, .hour, .minute });
	say "$stamp $msg";
	return 1;
}

sub drop {
	log("Dropping priviliges: uid=" ~ $config.{'whoissrv'}.{'drop-uid'} ~ ", gid=" ~ $config.{'whoissrv'}.{'drop-gid'});
	setuid($config.{'whoissrv'}.{'drop-uid'});
	setgid($config.{'whoissrv'}.{'drop-gid'});
}

sub connect-db {
	my $dbtype = $config.{"plugins"}.{"Database"}.{"driver"};
	die "Unsupported database type: $dbtype" unless $dbtype eq "SQLite";

	my $dbh = DBIish.connect($dbtype, database => "../" ~ $config.{"plugins"}.{"Database"}.{"dbname"});
	return $dbh;
}

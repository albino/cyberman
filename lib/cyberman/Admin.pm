package cyberman::Admin;
use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

use cyberman::Helper;

get '/admin' => sub {
	return auth_test("admin") if auth_test("admin");

	my $sth = database->prepare(
		"select count(*) from user",
	);
	$sth->execute;
	my $usercount = $sth->fetchrow_hashref->{"count(*)"};

	$sth = database->prepare(
		"select count(*) from domain",
	);
	$sth->execute;
	my $domaincount = $sth->fetchrow_hashref->{"count(*)"};

	return template "admin" => {
		usercount => $usercount,
		domaincount => $domaincount,
	};
};

get '/admin/users' => sub {
	return auth_test("admin") if auth_test("admin");

	my @users = database->quick_select(
		"user",
		{}
	);

	return template "admin/users" => {
		users => \@users,
	};
};

get '/admin/domains' => sub {
	return auth_test("admin") if auth_test("admin");

	my @domains = database->quick_select(
		"domain",
		{}
	);

	return template "admin/domains" => {
		domains => \@domains,
	};
};

true;

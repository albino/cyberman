package cyberman::Records;

use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

use cyberman::Helper;

get '/domains/:name/records' => sub {
	my $domain = database->quick_select(
		"domain",
		{
			"name" => param("name"),
		},
	);

	if (!$domain) {
		return "No such domain!";
	}

	return auth_test($domain->{"ownerid"}) if auth_test($domain->{"ownerid"});

	my @records = database->quick_select(
		"record",
		{
			"domainid" => $domain->{"id"},
		},
	);

	template 'records' => {
		domain => $domain,
		records => \@records,
	};
};

get '/domains/:name/records/add' => sub {
	my $domain = database->quick_select(
		"domain",
		{
			"name" => param("name"),
		},
	);

	if (!$domain) {
		return "No such domain!";
	}

	return auth_test($domain->{"ownerid"}) if auth_test($domain->{"ownerid"});

	template 'records/add' => {
		domain => $domain,
	};
};

post '/domains/:name/records/add' => sub {
	my $domain = database->quick_select(
		"domain",
		{
			"name" => param("name"),
		},
	);

	if (!$domain) {
		return "No such domain!";
	}

	return auth_test($domain->{"ownerid"}) if auth_test($domain->{"ownerid"});

	my ( $valid, $why );
	# 1 is a stand in for the TTL
	($valid, $why) = validate_record(param("rname"), 1, 'IN', param("type"), param("value"));

	if (!$valid) {
		return template 'records/add' => {
			domain => $domain,
			message => $why,
			error => 1,
		};
	}

	my $sid = $domain->{"lastsid"} + 1;
	database->quick_update(
		"domain",
		{
			"id" => $domain->{"id"},
		},
		{
			"lastsid" => $sid,
		},
	);

	database->quick_insert(
		"record",
		{
			"sid" => $sid,
			"domainid" => $domain->{"id"},
			"type" => param("type"),
			"name" => param("rname"),
			"value" => param("value"),
		},
	);

	template 'redir' => {
		"redir" => "../records?added=1",
	};
};

post '/domains/:name/records/:sid/remove' => sub {
	my $domain = database->quick_select(
		"domain",
		{
			"name" => param("name"),
		},
	);

	if (!$domain) {
		return "No such domain!";
	}

	return auth_test($domain->{"ownerid"}) if auth_test($domain->{"ownerid"});

	my $record = database->quick_select(
		"record",
		{
			"domainid" => $domain->{"id"},
			"sid" => param("sid"),
		},
	);

	if (!$record) {
		return "No such record!";
	}

	database->quick_delete(
		"record",
		{
			"domainid" => $domain->{"id"},
			"sid" => param("sid"),
		},
	);

	template 'redir' => {
		"redir" => "../../records?removed=1",
	};
};

true;

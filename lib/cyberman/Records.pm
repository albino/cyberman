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

my %patterns = (
	"ipv4" => qr/^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$/,
	"ipv6" => qr/^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/,
	"name" => qr/^([a-zA-Z0-9]([a-zA-Z0-9-_]*[a-zA-Z0-9])?\.)+$/,
);

my %tests = ( IN => {
	"A" => "ipv4",
	"AAAA" => "ipv6",
	"NS" => "name",
	"CNAME" => "name",
});

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

	my %errs;

	if ( exists($tests{"IN"}->{param("type")}) ) {
		if (param("value") !~ m/$patterns{ $tests{"IN"}->{param("type")} }/) {
			$errs{"e_bad_value"} = 1;
		}
	} else {
		$errs{"e_bad_type"} = 1;
	}

	if (param("rname") !~ m/^(@|([a-zA-Z0-9]([a-zA-Z0-9-_]*[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9-_]*[a-zA-Z0-9])?)$/) {
		$errs{"e_bad_name"} = 1;
	}

	if (scalar(keys(%errs)) != 0) {
		return template 'records/add' => {
			domain => $domain,
			%errs,
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

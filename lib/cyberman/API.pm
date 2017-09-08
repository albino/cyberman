package cyberman::API;
use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

use cyberman::Helper;

get '/api/check_availability' => sub {
	# No auth req'd
	# returns 'y' or 'n'

	if (!param("name")) {
		return "n";
	}

	if (!check_name(param "name")) {
		return "n";
	}

	my $result = database->quick_select(
		"domain",
		{
			"name" => param("name"),
		}
	);

	if ($result) {
		return "n";
	} else {
		return "y";
	}
};

get '/api/get_owner_email' => sub {
	return "" if auth_test("admin");
	if (!param("name")) {
		return "";
	}

	my $domain = database->quick_select(
		"domain",
		{
			"name" => param("name"),
		},
	);

	if (!$domain) {
		return "";
	};

	my $owner = database->quick_select(
		"user",
		{
			"id" => $domain->{"ownerid"},
		},
	);

	if (!$owner) {
		return "";
	}

	return $owner->{"email"};
};

true;

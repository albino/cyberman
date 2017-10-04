package cyberman::Account;
use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;
use URI::Escape;

use cyberman::Helper;

get '/account' => sub {
	return auth_test() if auth_test();

	my $user = database->quick_select(
		"user",
		{
			"id" => vars->{"auth"},
		},
	);

	template 'account' => {
		"user" => $user,
		"updated" => param("updated") ? 1 : 0,
	};
};

post '/account' => sub {
	return auth_test() if auth_test();

	my %errs;
	my $new_pass = 0;

	my $user = database->quick_select (
		"user",
		{
			"id" => vars->{"auth"},
		}
	);

	if (!param("email")) {
		$errs{"e_no_email"} = 1;
	}

	if (param("email") ne $user->{"email"}) {
		my $result = database->quick_select (
			"user",
			{
				"email" => param("email"),
			},
		);

		if ($result) {
			$errs{"e_email_exists"} = 1;
		}
	}

	if (param("password") || param("npassword") || param("npassword2")) {
		$new_pass = 1;

		my ($o_hash, $o_salt) = hash_password(param("password"), $user->{"salt"});
		if ($o_hash ne $user->{"password"}) {
			$errs{"e_wrong_pass"} = 1;
		}

		if (param "npassword" ne param "npassword2") {
			$errs{"e_pass_mismatch"} = 1;
		} elsif (length(param "npassword") < 8) {
			$errs{"e_pass_len"} = 1;
		}
	}

	if (!grep {$_ eq param("stylesheet")} @{ config->{"stylesheets"}->{"available"} }) {
		$errs{"e_bad_sheet"} = 1;
	}

	if (param("email_pub") !~ m/^[01]$/) {
		$errs{"e_bad_privacy"} = 1;
	}

	if (param("whois_name") !~ m/^[A-Za-z0-9 \'-]{0,64}$/) {
		$errs{"e_bad_name"} = 1;
	}

	if (scalar(keys %errs) != 0) {
		return template 'account' => {
			"user" => $user,
			error => 1,
			%errs,
		};
	}

	if (param("email") ne $user->{"email"}) {
		my $conftoken = randstring(16);

		database->quick_update (
			"user",
			{
				"id" => vars->{"auth"},
			},
			{
				"newemail" => param("email"),
				"conftoken" => $conftoken,
			},
		);

		my $email = template 'email/update' => {
			"link" => config->{"mail"}->{"baseurl"} . "/confirm_update?o=" . uri_escape($user->{"email"}) . "&n=" . uri_escape(param "email") . "&t=$conftoken",
		},
		{
			"layout" => undef,
		};
		send_email(param("email"), $email);
	}

	if ($new_pass) {
		my ($hash, $salt) = hash_password(param "npassword");
		database->quick_update (
			"user",
			{
				"id" => vars->{"auth"},
			},
			{
				"password" => $hash,
				"salt" => $salt,
			},
		);

		database->quick_delete (
			"session",
			{
				"uid" => vars->{"auth"},
			},
		);

		return template 'redir' => {
			"redir" => "login?pwchange=1",
		};
	}
	
	database->quick_update (
		"user",
		{
			"id" => vars->{"auth"},
		},
		{
			"stylesheet" => param("stylesheet"),
			"email_pub" => param("email_pub"),
			"whois_name" => param("whois_name"),
		},
	);

	my $newuser = database->quick_select (
		"user",
		{
			"id" => vars->{"auth"},
		},
	);

	# Instant stylesheet update
	if (!$user->{"stylesheet"}) {
		$user->{"stylesheet"} = 0;
	}
	if ($user->{"stylesheet"} ne $newuser->{"stylesheet"}) {
		return template 'redir' => {
			"redir" => "account?updated=1",
		};
	}

	template 'account' => {
		updated => 1,
		user => $newuser,
	};
};

get '/confirm_update' => sub {
	my $user = database->quick_select(
		"user",
		{
			"email" => param("o"),
			"newemail" => param("n"),
			"conftoken" => param("t"),
		},
	);

	if (!$user) {
		return "No such user/token!";
	}

	database->quick_update(
		"user",
		{
			"id" => $user->{"id"},
		},
		{
			"email" => param("n"),
		},
	);

	template 'confirmed';
};

true;

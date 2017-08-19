package cyberman::Auth;

use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;
use URI::Escape;

use cyberman::Helper;

# This file: auth-related routes (register, login, logout)
# Hooks and helper functions for authentication are in cyberman.pm

post '/register' => sub {
	my %errs;

	for my $param ("password", "password2", "email") {
		if (!param($param)) {
			$errs{"e_no_$param"} = 1;
		}
	}

	my $result = database->quick_select(
		"user",
		{
			"email" => param("email"),
		},
	);

	if ($result) {
		$errs{"e_email_exists"} = 1;
	}

	if (!exists $errs{"e_no_password"} || !exists $errs{"e_no_password2"}) {
		if (param("password") ne param("password2")) {
			$errs{"e_pass_match"} = 1;
		}

		if (length param("password") < 8) {
			$errs{"e_pass_len"} = 1;
		}
	}

	if (scalar(keys(%errs)) != 0) {
		return template 'register' => {
			error => 1,
			%errs,
		};
	}

	my ($hash, $salt) = hash_password(param("password"));
	my $conftoken = randstring(16);

	# Create the account in the database
	database->quick_insert(
		"user",
		{
			"email" => param("email"),
			"password" => $hash,
			"salt" => $salt,
			"conftoken" => $conftoken,
		},
	);

	# Send email
	my $email = template 'email/registration' => {
		"link" => config->{"mail"}->{"baseurl"} . "/confirm_new?e=" . uri_escape(param "email") . "&t=$conftoken",
	},
	{
		"layout" => undef,
	};
	send_email(param("email"), $email);

	template 'login' => {
		account_created => 1,
	};
};

post '/login' => sub {
	my %errs;

	my $user = database->quick_select(
		"user",
		{
			"email" => param("email"),
		},
	);

	if (!$user) {
		$errs{"e_no_user"} = 1;
	}

	if (scalar(keys(%errs)) == 0) {
		my ($hash, $salt) = hash_password(param("password"), $user->{"salt"});
		$errs{"e_pass"} = 1 unless $hash eq $user->{"password"};
	}

	if (scalar(keys(%errs)) == 0) {
		$errs{"e_not_confirmed"} = 1 unless $user->{"active"};
	}

	if (scalar(keys(%errs)) != 0) {
		return template 'login' => {
			error => 1,
			%errs,
		};
	}

	# checks finished, we can create a session now

	my $token = randstring(32);

	database->quick_insert(
		"session",
		{
			"token" => $token,
			"uid" => $user->{"id"},
			"since" => time,
		},
	);

	cookie id => $user->{"id"}, http_only => 1;
	cookie token => $token, http_only => 1;

	template 'redir' => {
		"redir" => "domains",
	};
};

get '/confirm_new' => sub {
	my $user = database->quick_select(
		"user",
		{
			"email" => param("e"),
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
			"active" => 1,
		},
	);

	template 'confirmed';
};

post '/logout' => sub {
	cookie 'id' => undef;
	cookie 'token' => undef;
	template 'redir' => {
		"redir" => "index",
	};
};

true;

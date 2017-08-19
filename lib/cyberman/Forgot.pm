package cyberman::Forgot;

use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;
use URI::Escape;

use cyberman::Helper;

post '/forgot' => sub {
	my $user = database->quick_select(
		"user",
		{
			"email" => param("email"),
		},
	);

	if (!$user) {
		return template 'forgot' => {
			err => 1,
			e_no_user => 1,
		};
	}

	my $token = randstring(32);
	database->quick_update(
		"user",
		{
			"id" => $user->{"id"},
		},
		{
			"recoverytoken" => $token,
		},
	);

	my $email = template 'email/forgot' => {
		"link" => config->{"mail"}->{"baseurl"} . "/confirm_forgot?e=" . uri_escape(param("email")) . "&t=$token",
	},
	{
		"layout" => undef,
	};
	send_email(param("email"), $email);

	template 'forgot' => {
		success => 1,
	};
};

post '/confirm_forgot' => sub {
	my %errs;

	if (!param("e") || !param("t")) {
		$errs{"e_bad_link"} = 1;
	} elsif (!param("password")) {
		$errs{"e_no_pass"} = 1;
	} elsif (length(param("password")) < 8) {
		$errs{"e_pass_len"} = 1;
	} elsif (param("password") ne param("password2")) {
		$errs{"e_pass_mismatch"} = 1;
	}

	if (scalar(keys(%errs)) == 0) {
		my $user = database->quick_select(
			"user",
			{
				"email" => param("e"),
				"recoverytoken" => param("t"),
			},
		);

		if (!$user) {
			$errs{"e_bad_link"} = 1;
		} else {
			# Update the password
			my ($hash, $salt) = hash_password(param "password");
			database->quick_update(
				"user",
				{
					"id" => $user->{"id"},
				},
				{
					"password" => $hash,
					"salt" => $salt,
				},
			);

			database->quick_delete(
				"session",
				{
					"uid" => $user->{"id"},
				},
			);

			database->quick_update(
				"user",
				{
					"id" => $user->{"id"},
				},
				{
					"recoverytoken" => "",
				},
			);
		}
	}

	if (scalar(keys(%errs)) != 0) {
		return template 'confirm_forgot' => {
			"err" => 1,
			%errs,
		};
	}

	template 'redir' => {
		"redir" => "login?pwchange=1",
	};
};

true;

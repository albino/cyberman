package cyberman;

use Dancer2;
use Dancer2::Plugin::Database;

use cyberman::Domains;
use cyberman::Auth;
use cyberman::Account;
use cyberman::Helper;
use cyberman::API;
use cyberman::Records;
use cyberman::Forgot;

# Index route, hook and helper functions for authentication

sub get_auth {
	my $uid = shift;
	my $token = shift;

	my $result = database->quick_select("session", {"uid" => $uid, "token" => $token});

	if ($result) {
		return $uid;
	} else {
		return 0;
	}
}

hook 'before' => sub {
	sub cookieval {
		my $name = shift;
		my $cookie = cookie($name);
		if ($cookie) {
			return $cookie->value;
		} else {
			return undef;
		}
	}

	my $uid = cookieval("id");
	my $token = cookieval("token");
	my $auth = 0;
	my $email;
	if ($uid && $token) {
		$auth = get_auth($uid, $token);
		$email = database->quick_lookup(
			"user",
			{
				"id" => $uid,
			},
			"email",
		);
	}

	var auth => $auth;
	var email => $email;
	var config => config();
};

get qr{^/(index)?$} => sub {
	if (!vars->{auth}) {
		return template 'index';
	}

	template 'redir' => {
		"redir" => "domains",
	};
};

true;

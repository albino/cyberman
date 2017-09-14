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
use cyberman::Admin;

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
	my $user;
	if ($uid && $token) {
		$auth = get_auth($uid, $token);
		$user = database->quick_select(
			"user",
			{
				"id" => $uid,
			},
		);
	}

	var auth => $auth;
	var email => $user->{"email"};
	var admin => $user->{"admin"};
	var config => config();

	if ($user->{"admin"}) {
		my $zone_check = database->quick_lookup(
			"cyberman",
			{},
			"zonecheckstatus",
		);
		if ($zone_check != 0) {
			var zone_check_alert => 1;
		}
	}

	if ($user->{"stylesheet"} && grep {$_ eq $user->{"stylesheet"}} @{ config->{"stylesheets"}->{"available"} }) {
		var stylesheet => $user->{"stylesheet"};
	} else {
		var stylesheet => config->{"stylesheets"}->{"default"};
	}
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

package cyberman::Helper;
use base qw(Exporter);
use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

use Math::Random::Secure qw(irand);
use Digest::Bcrypt;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

use Exporter qw(import);

our @EXPORT = qw(auth_test randstring hash_password check_name send_email incr_serial);

# Helper functions

sub auth_test {
	my $id = undef;
	if (@_) {
		$id = shift;
	}

	if (!vars->{"auth"}) {
		return template 'redir' => {
			"redir" => "/index",
		};
	} elsif ($id && $id eq "admin" && !vars->{"admin"}) {
		return template 'redir' => {
			"redir" => "/index",
		};
	} elsif ($id && $id eq "admin" && vars->{"admin"}) {
		return 0;
	} elsif ($id && vars->{"auth"} != $id) {
		return template 'redir' => {
			"redir" => "/index",
		};
	} else {
		return 0; # nothing to be returned, route can continue
	}
}

sub randstring {
	my $len = shift;

	my @chars = (0..9, "a".."z", "A".."Z");
	my $ret;

	for (1..$len) {
		$ret .= $chars[irand(scalar(@chars))];
	}
	return $ret;
}

sub hash_password {
	my $plaintext = shift;

	my $salt;
	if (scalar(@_) > 0) {
		$salt = shift;
	} else {
		$salt = randstring(16);
	}

	my $b = new Digest::Bcrypt;
	$b->cost(8);
	$b->salt($salt);
	$b->add($plaintext);

	return ($b->bcrypt_b64digest, $salt);
}

sub check_name {
	my $name = shift;
	if ($name =~ m/^[a-z0-9]([a-z0-9\-_]*[a-z0-9])?$/ && length($name) <= 63) {
		return 1;
	} else {
		return 0;
	}
}

sub send_email {
	my $addy = shift;
	my $body = shift;

	# TODO: this function is quick and dirty to get this
	# online - it needs to be rewritten so it doesn't block the thread!!

	my $email = Email::Simple->create(
		header => [
			To => $addy,
			From => config->{"mail"}->{"from"},
			Subject => "Confirm your email address",
		],
		body => $body,
	);

	sendmail($email) if config->{"mail"}->{"enabled"};
}

sub incr_serial {
	my $cyberman = database->quick_select(
		"cyberman",
		{},
	);
	database->quick_update(
		"cyberman",
		{},
		{
			"intserial" => $cyberman->{"intserial"} + 1,
		},
	);
	return 1;
}

1;

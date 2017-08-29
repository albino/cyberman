package cyberman::Helper;
use base qw(Exporter);
use Dancer2 appname => "cyberman";

use Math::Random::Secure qw(irand);
use Digest::Bcrypt;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

use Exporter qw(import);

our @EXPORT = qw(auth_test randstring hash_password check_name send_email validate_record);

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


sub validate_record {
	my $retval = 1;
	my $msg = '';
	my ( $label, $ttl, $class, $type, $rdata ) = @_;

	test_ttl($ttl, \$retval, \$msg); #Same rules for all ttls for now

	if ( $class eq 'IN' )
	{
		if ( $type eq 'A' )
		{
			test_basic_name($label, \$retval, \$msg);
			test_ipv4($rdata, \$retval, \$msg);
			return $retval, $msg;
		}
		if ( $type eq 'AAAA' )
		{
			test_basic_name($label, \$retval, \$msg);
			test_ipv6($rdata, \$retval, \$msg);
			return $retval, $msg;
		}
		if ( $type eq 'CNAME' or $type eq 'NS' )
		{
			test_basic_name($label, \$retval, \$msg);
			test_basic_name($rdata, \$retval, \$msg);
			return $retval, $msg;
		}
		else
		{
			return 0, "Unsupported class/type: $class $type";
		}
	}
	else
	{
		return 0, "Unsupported class/type: $class $type";
	}
	return 0, "ERROR: An internal error has occured.  Please report the following error code to the operators: HVR01";
}

sub test_ttl {
	my ( $ttl, $retval, $msg ) = @_;
	# min and max ttl should be defined in the config
	my $min_ttl = 0;
	my $max_ttl = 17280; # 2 days - Allowing too long is just asking for cache poisoning
	if ( $ttl !~ /^\d+$/ or $ttl < $min_ttl or $ttl > $max_ttl )
	{
		$$msg .= "Error: TTL must be a number between $min_ttl and $max_ttl!\n";
		$$retval = 0;
	}
}

sub test_basic_name {
	my ( $name, $retval, $msg ) = @_;
	if ( $name !~ /(?:^\@$)|(?:^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-_]*[a-zA-Z0-9])?(?:\.|$))+$)/ )
	{
		$$msg .= "Error: name contains invalid characters!\n";
		$$retval = 0;
	}
	if ( length($name) > 255 ) 
	{
		$$msg .= "Name exceeds maximum length of 255 octets!\n";
		$$retval = 0;
	}
	if ( $name !~ /^(?:.{1,63}(?:\.|$))+/ )
	{
		$$msg .= "Error: label in name exceeds maximum length of 63 octets!\n";
		$$retval = 0;
	}
}

sub test_ipv4 {
	my ( $addr, $retval, $msg ) = @_;
	if ( $addr !~ /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$/ )
	{
		$$msg .= "Invalid IPv4 address!\n";
		$$retval = 0;
	}
}

sub test_ipv6 {
	my ( $addr, $retval, $msg ) = @_;
	if ( $addr !~ /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/ ) # this is pure cancer and needs to be fixed
	{
		$$msg .= "Invalid IPv6 address!\n";
		$$retval = 0;
	}
}

1;

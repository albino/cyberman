package cyberman::Helper;
use base qw(Exporter);
use Dancer2 appname => "cyberman";

use Math::Random::Secure qw(irand);
use Digest::Bcrypt;

use Exporter qw(import);

our @EXPORT = qw(auth_test randstring hash_password);

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

1;

package cyberman::Helper;
use base qw(Exporter);
use Dancer2 appname => "cyberman";

use Math::Random::Secure qw(irand);

use Exporter qw(import);

our @EXPORT = qw(auth_test randstring);

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

1;

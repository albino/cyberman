package cyberman::Helper;
use base qw(Exporter);
use Dancer2 appname => "cyberman";
use Exporter qw(import);

our @EXPORT = qw(auth_test);

sub auth_test {
  if (!vars->{"auth"}) {
    return template 'redir' => {
      "redir" => "/index",
    };
  } else {
    return 0; # nothing to be returned, route can continue
  }
}

1;

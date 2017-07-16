package cyberman::Domains;

use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

get '/domains' => sub {
  return template 'redir' => {
    "redir" => "index",
  } unless vars->{"auth"};

  my @domains = database->quick_select(
    "domain",
    {
      "ownerid" => vars->{"auth"},
    },
  );

  template 'domains' => {
    "domains" => \@domains,
  }
};

true;

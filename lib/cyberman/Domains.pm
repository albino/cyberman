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

post '/domains/new' => sub {
  my %errs;

  if (!param("name")) {
    $errs{"e_no_name"} = 1;
  }

  my $name = lc param("name");

  if (scalar(keys(%errs)) == 0) {
    if (param("name") !~ m/^[a-z0-9]([a-z0-9\-_]*[a-z0-9])?$/) {
      $errs{"e_chars"} = 1;
    }
  }

  if (scalar(keys(%errs)) == 0) {
    my $result = database->quick_select(
      "domain",
      {
        "name" => param("name"),
      },
    );

    if ($result) {
      $errs{"e_exists"} = 1;
    }
  }

  if (scalar(keys(%errs)) != 0) {
    return template 'domains/new' => {
      params,
      %errs,
      error => 1,
    };
  }

  # TODO: send domains to nsd

  database->quick_insert(
    "domain",
    {
      "name" => $name,
      "ownerid" => vars->{"auth"},
    },
  );

  template 'redir' => {
    "redir" => "../domains?new=$name",
  };
};

true;

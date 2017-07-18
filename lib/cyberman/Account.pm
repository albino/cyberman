package cyberman::Account;
use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

use cyberman::Helper;

get '/account' => sub {
  return auth_test() if auth_test();

  my $user = database->quick_select(
    "user",
    {
      "id" => vars->{"auth"},
    },
  );

  template 'account' => {
    "user" => $user,
  };
};

post '/account' => sub {
  return auth_test() if auth_test();

  my %errs;
  my $new_pass = 0;

  my $user = database->quick_select (
    "user",
    {
      "id" => vars->{"auth"},
    }
  );

  if (!param("email")) {
    $errs{"e_no_email"} = 1;
  }

  if (param("email") ne $user->{"email"}) {
    my $result = database->quick_select (
      "user",
      {
        "email" => param("email"),
      },
    );
    
    if ($result) {
      $errs{"e_email_exists"} = 1;
    }
  }

  if (param("password") || param("npassword") || param("npassword2")) {
    $new_pass = 1;

    my ($o_hash, $o_salt) = hash_password(param("password"), $user->{"salt"});
    if ($o_hash ne $user->{"password"}) {
      $errs{"e_wrong_pass"} = 1;
    }

    if (param "npassword" ne param "npassword2") {
      $errs{"e_pass_mismatch"} = 1;
    } elsif (length(param "npassword") < 8) {
      $errs{"e_pass_len"} = 1;
    }
  }

  if (scalar(keys %errs) != 0) {
    return template 'account' => {
      "user" => $user,
      error => 1,
      %errs,
    };
  }

  if (param("email") ne $user->{"email"}) {

    # TODO: verify email address here

    database->quick_update (
      "user",
      {
        "id" => vars->{"auth"},
      },
      {
        "email" => param "email",
      },
    );
  }

  if ($new_pass) {
    my ($hash, $salt) = hash_password(param "npassword");
    database->quick_update (
      "user",
      {
        "id" => vars->{"auth"},
      },
      {
        "password" => $hash,
        "salt" => $salt,
      },
    );

    database->quick_delete (
      "session",
      {
        "uid" => vars->{"auth"},
      },
    );

    return template 'redir' => {
      "redir" => "login?pwchange=1",
    };
  }

  $user = database->quick_select (
    "user",
    {
      "id" => vars->{"auth"},
    },
  );

  template 'account' => {
    updated => 1,
    user => $user,
  };
};

true;

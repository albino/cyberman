package cyberman::Auth;

use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;
use Digest::Bcrypt;
use Math::Random::Secure qw(irand);

use cyberman::Helper;

# This file: auth-related routes (register, login, logout)
# Hooks and helper functions for authentication are in cyberman.pm

post '/register' => sub {
  my %errs;

  for my $param ("password", "password2", "email") {
    if (!param($param)) {
      $errs{"e_no_$param"} = 1;
    }
  }

  if (!exists $errs{"e_no_password"} || !exists $errs{"e_no_password2"}) {
    if (param("password") ne param("password2")) {
      $errs{"e_pass_match"} = 1;
    }

    if (length param("password") < 8) {
      $errs{"e_pass_len"} = 1;
    }
  }

  if (scalar(keys(%errs)) != 0) {
    return template 'register' => {
      error => 1,
      %errs,
    };
  }

  # Hash password
  my $salt = randstring(16);

  my $b = new Digest::Bcrypt;
  $b->cost(8);
  $b->salt($salt);
  $b->add(param "password");

  # Create the account in the database
  database->quick_insert(
    "user",
    {
      "email" => param("email"),
      "password" => $b->bcrypt_b64digest,
      "salt" => $salt,
    },
  );

  # TODO: send confirmation email

  template 'login' => {
    account_created => 1,
  };
};

post '/login' => sub {
  my %errs;

  my $user = database->quick_select(
    "user",
    {
      "email" => param("email"),
    },
  );

  if (!$user) {
    $errs{"e_no_user"} = 1;
  }

  if (scalar(keys(%errs)) == 0) {
    my $b = new Digest::Bcrypt;
    $b->cost(8);
    $b->salt($user->{"salt"});
    $b->add(param "password");

    $errs{"e_pass"} = 1 unless $b->bcrypt_b64digest eq $user->{"password"};
  }

  if (scalar(keys(%errs)) == 0) {
    $errs{"e_not_confirmed"} = 1 unless $user->{"active"};
  }

  if (scalar(keys(%errs)) != 0) {
    return template 'login' => {
      error => 1,
      %errs,
    };
  }

  # checks finished, we can create a session now

  my $token = randstring(32);

  database->quick_insert(
    "session",
    {
      "token" => $token,
      "uid" => $user->{"id"},
      "since" => time,
    },
  );

  cookie id => $user->{"id"}, http_only => 1;
  cookie token => $token, http_only => 1;

  template 'redir' => {
    "redir" => "domains",
  };
};

post '/logout' => sub {
  cookie 'id' => undef;
  cookie 'token' => undef;
  template 'redir' => {
    "redir" => "index",
  };
};

true;

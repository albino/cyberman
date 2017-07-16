package cyberman;

use Dancer2;

use cyberman::Domains;

use Dancer2::Plugin::Database;
use Digest::Bcrypt;
use Math::Random::Secure qw(rand irand);

#####
# cyberman.pm
# index page and authentication
# maybe this could be split into another file at a later juncture
#####

# misc authentication subs

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

sub randstring {
  my $len = shift;

  my @chars = (0..9, "a".."z", "A".."Z");
  my $ret;

  for (1..$len) {
    $ret .= $chars[irand(scalar(@chars))];
  }
  return $ret;
}

prefix undef;

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
  my $email;
  if ($uid && $token) {
    $auth = get_auth($uid, $token);
    $email = database->quick_lookup(
      "user",
      {
        "id" => $uid,
      },
      "email",
    );
  }

  var auth => $auth;
  var email => $email;
};

get qr{^/(index)?$} => sub {
  if (!vars->{auth}) {
    return template 'index';
  }

  template 'redir' => {
    "redir" => "domains",
  };
};

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
      params,
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
    params,
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
      params,
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

  cookie id => $user->{"id"};
  cookie token => $token;

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

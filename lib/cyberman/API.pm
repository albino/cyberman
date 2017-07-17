package cyberman::API;
use Dancer2 appname => "cyberman";
use Dancer2::Plugin::Database;

get '/api/check_availability' => sub {
  # No auth req'd
  # returns 'y' or 'n'
  
  # TODO: check name validity here

  if (!param("name")) {
    return "n";
  }

  my $result = database->quick_select(
    "domain",
    {
      "name" => param("name"),
    }
  );

  if ($result) {
    return "n";
  } else {
    return "y";
  }
};

true;

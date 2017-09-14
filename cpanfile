requires "Dancer2" => "0.205001";

requires "YAML"             => "0";
requires "YAML::Tiny" => "0";
requires "URL::Encode::XS"  => "0";
requires "CGI::Deurl::XS"   => "0";
requires "HTTP::Parser::XS" => "0";
requires "Dancer2::Plugin::Database" => "0";
requires "DBD::SQLite" => "0";
requires "HTML::Entities" => "0";
requires "Digest::Bcrypt" => "0";
requires "Math::Random::Secure" => "0";
requires "Email::Simple" => "0";
requires "Email::Simple::Creator" => "0";
requires "Email::Sender::Simple" => "0";
requires "URI::Escape" => "0";
requires "Capture::Tiny" => "0";

requires "Plack::Middleware::Deflater" => "0";
requires "Plack::Middleware::Session" => "0";
requires "Plack::Middleware::CSRFBlock" => "0";

on "test" => sub {
	requires "Test::More"            => "0";
	requires "HTTP::Request::Common" => "0";
};

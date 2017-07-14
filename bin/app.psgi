#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use cyberman;

cyberman->to_app;

use Plack::Builder;

builder {
    enable 'Deflater';
    cyberman->to_app;
}



=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use cyberman;
use Plack::Builder;

builder {
    enable 'Deflater';
    cyberman->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use cyberman;
use cyberman_admin;

builder {
    mount '/'      => cyberman->to_app;
    mount '/admin'      => cyberman_admin->to_app;
}

=end comment

=cut


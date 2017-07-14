#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use cyberman;

cyberman->to_app;

use Plack::Builder;

builder {
    enable 'Deflater';
    cyberman->to_app;
}


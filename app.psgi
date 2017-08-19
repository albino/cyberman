#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use cyberman;
use Plack::Builder;

builder {
	enable "Deflater";
	enable "Session";
	enable "CSRFBlock";
	cyberman->to_app;
}

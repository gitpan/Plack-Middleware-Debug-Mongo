use strict;
use Test::More tests => 2;

BEGIN {
    use_ok('Plack::Middleware::Debug::Mongo');
    use_ok('Plack::Middleware::Debug::Mongo::ServerStatus');
};

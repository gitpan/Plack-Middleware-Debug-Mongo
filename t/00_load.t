use strict;
use Test::More tests => 3;

BEGIN {
    use_ok('Plack::Middleware::Debug::Mongo');
    use_ok('Plack::Middleware::Debug::Mongo::ServerStatus');
    use_ok('Plack::Middleware::Debug::Mongo::Database');
};

use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Test::MockObject;
use MongoDB;
use boolean ();

my $SERVER_STATUS = {
    'ok'        => 1,
    'version'   => '2.2.0',
    'uptime'    => 1738371,
    'process'   => 'mongod',
    'network'   => {
        'bytesIn'       => 43218,
        'bytesOut'      => 9235789924,
        'numRequests'   => 548
    },
    'mem'       => {
        'bits'              => 64,
        'mapped'            => 1056,
        'mappedWithJournal' => 2112,
        'note'              => 'not all mem info support on this platform',
        'supported'         => boolean::false
    },
    'writeBacksQueued'  => boolean::true,
};

# Faked items: mongo, client, database, cursor, collection
my ($mdb, $cli, $dbh, $cur, $col);

BEGIN {
    ($mdb, $cli, $dbh, $cur, $col) = map { Test::MockObject->new } 1..5;

    Test::MockObject->fake_module('MongoDB',              new => sub { $mdb });
    Test::MockObject->fake_module('MongoDB::MongoClient', new => sub { $cli });
    Test::MockObject->fake_module('MongoDB::Database',    new => sub { $dbh });
    Test::MockObject->fake_module('MongoDB::Cursor',      new => sub { $cur });
    Test::MockObject->fake_module('MongoDB::Collection',  new => sub { $col });

    $mdb->mock('VERSION'      => sub { '0.502' });
    $cli->mock('get_database' => sub { $dbh });
    $dbh->mock('run_command'  => sub { $SERVER_STATUS });
}

{
    use Plack::Middleware::Debug::Mongo::ServerStatus 'hashwalk';
    can_ok 'Plack::Middleware::Debug::Mongo::ServerStatus', qw/prepare_app run/;
    ok(defined &hashwalk, 'Mongo-ServerStatus: hashwalk imported');
}

# simple application
my $app = sub {
    [
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ];
};

{
    $app = builder {
        enable 'Debug',
            panels => [
                [ 'Mongo::ServerStatus', connection => { host => 'mongodb://localhost:27017', db_name => 'sampledb' } ],
            ];
        $app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200, 'Mongo-ServerStatus: response code 200';

        like $res->content,
            qr|<a href="#" title="Mongo::ServerStatus" class="plDebugServerStatus\d+Panel">|m,
            'Mongo-ServerStatus: panel found';

        like $res->content,
            qr|<small>Version: \d\.\d{1,2}\.\d{1,2}</small>|,
            'Mongo-ServerStatus: subtitle points to mongod version';

        like $res->content,
            qr|<td>uptime</td>[.\s\n\r]*<td>1738371</td>|m,
            'Mongo-ServerStatus: found uptime and its value';

        like $res->content,
            qr|<td>network.bytesOut</td>[.\s\n\r]*<td>9235789924</td>|m,
            'Mongo-ServerStatus: found network.bytesOut and its value';

        like $res->content,
            qr|<td>mem.bits</td>[.\s\n\r]*<td>64</td>|m,
            'Mongo-ServerStatus: found mem.bits and its value';

        like $res->content,
            qr|<td>mem.supported</td>[.\s\n\r]*<td>false</td>|m,
            'Mongo-ServerStatus: found mem.supported and its value (translated from boolean)';
    };
}

done_testing();

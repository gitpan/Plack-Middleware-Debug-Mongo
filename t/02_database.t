use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Test::MockObject;
use MongoDB;

{
    use Plack::Middleware::Debug::Mongo::Database;
    can_ok 'Plack::Middleware::Debug::Mongo::Database', qw/prepare_app run/;
}

# Faked items: mongo, client, database, cursor, collection
my ($mdb, $cli, $dbh, $cur, $col);

my $STATS = {
    'db' => {
        'avgObjSize'        => 643.318918918919,
        'collections'       => 8,
        'flags'             => 1,
        'dataSize'          => 476056,
        'db'                => 'sampledb',
        'fileSize'          => 201326592,
        'indexSize'         => 81760,
        'indexes'           => 6,
        'nsSizeMB'          => 16,
        'numExtents'        => 11,
        'objects'           => 740,
        'ok'                => 1,
        'storageSize'       => 585728,
    },
    'models' => {
        'avgObjSize'        => 1459.75,
        'count'             => 16,
        'flags'             => 1,
        'indexSizes'        => {
            '_id_'  => 8176,
        },
        'lastExtentSize'    => 24576,
        'nindexes'          => 1,
        'ns'                => 'sampledb.models',
        'numExtents'        => 1,
        'ok'                => 1,
        'paddingFactor'     => 1,
        'size'              => 23356,
        'storageSize'       => 24576,
        'totalIndexSize'    => 8176,
    },
    'sessions' => {
        'avgObjSize'        => 1074.67768595041,
        'count'             => 363,
        'flags'             => 1,
        'indexSizes'        => {
            '_id_'  => 24528,
        },
        'lastExtentSize'    => 327680,
        'nindexes'          => 1,
        'ns'                => 'sampledb.sessions',
        'numExtents'        => 3,
        'ok'                => 1,
        'paddingFactor'     => 1,
        'size'              => 390108,
        'storageSize'       => 430080,
        'totalIndexSize'    => 24528,
    }
};

BEGIN {
    ($mdb, $cli, $dbh, $cur, $col) = map { Test::MockObject->new } 1..5;

    Test::MockObject->fake_module('MongoDB',              new => sub { $mdb });
    Test::MockObject->fake_module('MongoDB::MongoClient', new => sub { $cli });
    Test::MockObject->fake_module('MongoDB::Database',    new => sub { $dbh });
    Test::MockObject->fake_module('MongoDB::Cursor',      new => sub { $cur });
    Test::MockObject->fake_module('MongoDB::Collection',  new => sub { $col });

    $mdb->mock('VERSION'      => sub { '0.502' });
    $cli->mock('get_database' => sub { $dbh });
    $dbh->mock('collection_names' => sub { (qw(models sessions)) });
    $dbh->mock('run_command'  => sub {
        my ($self, $args) = @_;
        exists $args->{dbStats}
            ? $STATS->{db}
            : (exists $args->{collStats} && exists $STATS->{$args->{collStats}})
                ? $STATS->{$args->{collStats}}
                : {};
    });
}

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
                [ 'Mongo::Database', connection => { host => 'mongodb://localhost:27017', db_name => 'sampledb' } ],
            ];
        $app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200, 'Mongo-Database: response code 200';

        like $res->content,
            qr|<a href="#" title="Mongo::Database" class="plDebugDatabase\d+Panel">|m,
            'Mongo-Database: panel found';

        like $res->content,
            qr|<small>sampledb</small>|,
            'Mongo-Database: subtitle points to sampledb';

        like $res->content,
            qr|<h3>Collection: models</h3>| &&
            qr|<td>avgObjSize</td>[.\s\n\r]*<td>1459.75</td>| &&
            qr|<td>count</td>[.\s\n\r]*<td>16</td>| &&
            qr|<td>indexSizes\._id_</td>[.\s\n\r]*<td>8176</td>| &&
            qr|<td>lastExtentSize</td>[.\s\n\r]*<td>24576</td>| &&
            qr|<td>ns</td>[.\s\n\r]*<td>sampledb.models</td>|,
            'Mongo-Database: has models collection statistics';

        like $res->content,
            qr|<h3>Collection: sessions</h3>| &&
            qr|<td>count</td>[.\s\n\r]*<td>363</td>| &&
            qr|<td>indexSizes\._id_</td>[.\s\n\r]*<td>24528</td>| &&
            qr|<td>ns</td>[.\s\n\r]*<td>sampledb.sessions</td>| &&
            qr|<td>numExtents</td>[.\s\n\r]*<td>3</td>| &&
            qr|<td>storageSize</td>[.\s\n\r]*<td>430080</td>|,
            'Mongo-Database: has sessions collection statistics';

        like $res->content,
            qr|<h3>Database: sampledb</h3>| &&
            qr|<td>avgObjSize</td>[.\s\n\r]*<td>643.318918918919</td>| &&
            qr|<td>collections</td>[.\s\n\r]*<td>8</td>| &&
            qr|<td>fileSize</td>[.\s\n\r]*<td>201326592</td>| &&
            qr|<td>nsSizeMB</td>[.\s\n\r]*<td>16</td>| &&
            qr|<td>objects</td>[.\s\n\r]*<td>740</td>|,
            'Mongo-Database: has sampledb statistics';
    };
}

done_testing();

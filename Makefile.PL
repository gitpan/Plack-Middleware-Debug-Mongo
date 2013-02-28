use 5.008009;
use ExtUtils::MakeMaker;

my $git_repo = 'https://github.com/Wu-Wu/Plack-Middleware-Debug-Mongo';

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository => $git_repo,
            bugtracker => $git_repo . '/issues',
        },
    }
};

my %options = (
    NAME          => 'Plack::Middleware::Debug::Mongo',
    VERSION_FROM  => 'lib/Plack/Middleware/Debug/Mongo.pm',
    AUTHOR        => 'Anton Gerasimov <chim@cpan.org>',
    ABSTRACT_FROM => 'lib/Plack/Middleware/Debug/Mongo.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'strict'                   => 0,
        'warnings'                 => 0,
        'parent'                   => 0,
        'Plack'                    => 0,
        'Plack::Middleware::Debug' => 0,
        'MongoDB'                  => '0.502',
    },
    BUILD_REQUIRES => {
        'Test::More'       => '0.98',
        'Test::Pod'        => '1.22',
        'Plack'            => 0,
        'HTTP::Message'    => 0,
        'Test::MockObject' => 0,
        'boolean'          => 0,
    },
    MIN_PERL_VERSION => '5.8.9',
    test => {
        TESTS => 't/*.t',
    },
    clean => {
        FILES => '*.tar.gz',
    },
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
);

WriteMakefile(%options);

package Plack::Middleware::Debug::Mongo;

use strict;
use warnings;

our $VERSION = '0.01';

1; # End of Plack::Middleware::Debug::Mongo
__END__

=head1 NAME

Plack::Middleware::Debug::Mongo - Extend Plack::Middleware::Debug with MongoDB panels

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # inside your psgi app
    use Plack::Builder;

    my $app = sub {[
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ]};

    my $options = { host => 'mongodb://mongo.example.com:29111' };

    builder {
        mount '/' => builder {
            enable 'Debug',
                panels => [
                    [ 'Mongo::ServerStatus', connection => $options ],
                ];
            $app;
        };
    };

=head1 DESCRIPTION

This distribution extends Plack::Middleware::Debug with some MongoDB panels. At the moment, listed below panels are
available.

=head1 PANELS

=head2 Mongo::ServerStatus

Display panel with generic MongoDB server information which is available by the command I<db.serverStatus()>.
See L<Plack::Middleware::Debug::Mongo::ServerStatus> for additional information.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Mongo/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Mongo::ServerStatus>

L<Plack::Middleware::Debug>

L<MongoDB>

=head1 AUTHOR

Anton Gerasimov, E<lt>chim@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Anton Gerasimov

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

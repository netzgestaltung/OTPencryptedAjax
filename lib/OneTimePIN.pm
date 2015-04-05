package CGI::Application::Plugin::Authentication::Driver::OneTimePIN;

use strict;
use warnings;
our $VERSION = '0.20';

use base qw(CGI::Application::Plugin::Authentication::Driver);
use Data::Dumper qw(Dumper);

=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Generic - Generic Authentication driver

=head1 VERSION

This document describes CGI::Application::Plugin::Authentication::Driver::Generic version 0.20

=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authentication;

  __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user1 => '123', user2 => '123' } ],
  );

=head1 DESCRIPTION

This Driver offers a simple way to provide a user database to the
L<CGI::Application::Plugin::Authentication> plugin.  It offers three ways
to provide a list of users to the plugin by providing a hash of username/password pairs,
an array of arrays containing the username and password pairs, or a code
reference that returns back the username, or undef on success or failure.

=head1 EXAMPLE

  my %users = (
    user1 => '123',
    user2 => '123',
  );
  __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', \%users ],
  );

  - or -

  my @users = (
    ['example.com', 'user1', '123'],
    ['example.com', 'user2', '123'],
    ['foobar.com', 'user1', '123'],
  );
  __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', \@users ],
        CREDENTIALS => [ 'authen_domain', 'authen_username', 'authen_password' ]
  );

  - or -

  sub check_password {
    my @credentials = @_;
    if ($credentials[0] eq 'test' && $credentials[1] eq 'secret') {
        return 'testuser';
    }
    return;
  }

  __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', \&check_password ],
  );


=head1 METHODS

=head2 initialize

This method will be called right after a new Driver object is created.
So any startup customizations can be dealt with here.

=cut

sub initialize {
    my $self    = shift;
    print STDERR "opening etc/onetimepin\n";
    my @options = $self->options;
    print STDERR "filename: ".$options[0] ."\n";

    if (((length $options[0]) > 0) && (-r $options[0])) {
       open (my $pins, "<", $options[0]);
            print STDERR "starting while\n";
       while (<$pins>) {
         if ($_ =~ /^([^:]+):(\d+)$/) {
            $self->{secretPIN}->{$1} = $2;
            print STDERR "parsing onetimepin\n";
         } else {
            print STDERR "skipping line in onetimepin\n";
         }
       }
       close $pins;
    }
  #  print STDERR "options after initialize: ".(Dumper $self->authen);

    
}


=head2 verify_credentials

This method will test the provided credentials against either the hash ref, array ref or code ref
that the driver was configured with.

=cut

sub verify_credentials {
    my $self    = shift;
    my @creds   = @_;
    my @options = $self->options;
    my $data = $options[0];

    if ( ref $data eq 'HASH' ) {
        return undef unless( defined( $creds[0] ) && defined( $creds[1] ) );
        return ( defined $data->{ $creds[0] } && $data->{ $creds[0] } eq $creds[1] ) ? $creds[0] : undef;
    } elsif ( ref $data eq 'ARRAY' ) {
        foreach my $row (@$data) {
            return $creds[0] unless grep { !defined $creds[$_] || $creds[$_] ne $row->[$_] } 0..$#$row;
        }
        return undef;
    } elsif ( ref $data eq 'CODE' ) {
        return $data->(@creds);
    }
    die "Unknown options for Generic Driver";
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, L<CGI::Application::Plugin::Authentication>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;

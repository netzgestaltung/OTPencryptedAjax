package raw;

=head1 NAME

raw - private communication for everybody

=head1 SYNOPSIS

    use raw;
    my $app = raw->new();
    $app->run();

=head1 ABSTRACT

A brief summary of what raw does.

=cut

use warnings;
use strict;
use base 'CGI::Application';
use Carp qw( croak );
use File::ShareDir qw( dist_dir );
use File::Spec qw();
use Data::Dumper qw/Dumper/;
use CGI::Application::Plugin::LogDispatch;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use CGI::Application::Plugin::Authentication::Driver::OneTimePIN;
use Digest::SHA qw(sha256_hex);
use Crypt::CBC;
use Crypt::Cipher::AES;
use MIME::Base64 qw( encode_base64 decode_base64 );
use JSON::XS;
use Fcntl;   # For O_RDWR, O_CREAT, etc.
use NDBM_File;


=head1 VERSION

This document describes raw Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

this will be my try to implement secure communication via embedded
javascript security

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Sets up the run mode dispatch table and the start, error, and default run modes.
If the template path is not set, sets it to a default value.

TODO: change all these values to ones more appropriate for your application.

=cut

sub setup {
    my ($self) = @_;

    # calling log_config is optional as
    # some simple defaults will be used
    $self->log_config(
      LOG_DISPATCH_MODULES => [ 
        {    module => 'Log::Dispatch::File',
               name => 'debug',
           filename => '/home/raphael/tmp/debug.log',
          min_level => 'debug',
            newline => 1,
        },
      ]
    );

    # Configure the session
    $self->session_config(
       CGI_SESSION_OPTIONS => [ "driver:sqlite", $self->query||$self->session->id, {Directory=>'/home/raphael/tmp'} ],
       DEFAULT_EXPIRY      => '+1w',
       COOKIE_PARAMS       => {
                                -domain => 'localhost',
                                -expires => '+24h',
                                -path    => '/',
                              },
       SEND_COOKIE         => 1,
    );

    $self->authen->config(
#                                vvv  DRIVER name, before the password file
                    DRIVER => [ 'OneTimePIN', $ENV{PWD}.'/etc/onetimepin',
                                              $ENV{PWD}.'/etc/avatare/',
                                              $ENV{PWD}.'/etc/unknown_users',
],
                     STORE => 'Session',
             LOGIN_RUNMODE => 'login_form',
        POST_LOGIN_RUNMODE => 'auth_welcome',
            LOGOUT_RUNMODE => 'logout',
               CREDENTIALS => [ 'authen_username', 'authen_secret_pin', 
                                'authen_key', 'authen_password' ]
    );

    $self->authen->protected_runmodes(qr/^auth_/);

    $self->session_cookie(-secure => 1, -expires => '+24h');

    $self->header_add(-charset => "utf-8");

    $self->start_mode('login_form');
    $self->error_mode('error');
    $self->run_modes( [qw/login_form authenticate get_challenge enc_req send_encrypted/] );
    if ( !$self->tmpl_path ) {
        $self->tmpl_path(
            File::Spec->catdir( dist_dir('raw'), 'share', 'templates' ) );
    }
    $self->run_modes( AUTOLOAD => 'login_form' );

# now we seed the random number generator

    # we read random data from /dev/urandom
    my ($i, $str1, $str2) = (0, "", "");
    printf STDERR "opening /dev/urandom...\n";
    open(my $random, '<', "/dev/urandom") or die $!;
    while ($i < 2) {
       $i += read $random, $str1, 2-$i;
       $str2 .= $str1;
    }
    close $random;
    srand( time ^ $$ ^ hex((unpack "H*", $str2)) );
 
    return;
}

sub cgiapp_prerun {
   my $self = shift;

    $self->log->info("in cgiapp_prerun()");
    if (exists $ENV{PATH_INFO}) { 
      $self->log->info("PATH_INFO: ".$ENV{PATH_INFO});
      $self->log->info("calling authen->drivers->init()");
      my $res = $self->authen->drivers->initialize();
      $self->log->debug("dumping init res: [".(Dumper $res)."]");
    }

}


=pod

TODO: Other methods inherited from CGI::Application go here.

=head2 RUN MODES

=head3 login_form

  * Purpose
shows the username / password form to the user
  * Expected parameters
possibly a uid or a nonce
  * Function on success
set to authenticated
  * Function on failure
show login form again, block user after too many failed login attempts


=cut

sub login_form {
    my ($self) = @_;

    $self->log->info("in login_form()");
    $self->log->info("remote host $ENV{'REMOTE_HOST'} connected from port $ENV{'REMOTE_PORT'}");
#    $self->log->debug("dumping self->dump: [".(Dumper $self->dump())."]");

    my $template = $self->load_tmpl;
    $template->param( message => "Welcome $ENV{'REMOTE_HOST'}" );
    $template->param( client_ip => "\"$ENV{'REMOTE_HOST'}\"" );
    return $template->output;
}


sub error {
    my $self = shift;
    my $error_msg = shift;

    $self->log->info("in error()");
    $self->log->info("error params: [".(Dumper @_)."]");
    $self->log->debug("dumping self->query dump: [".(Dumper $self->dump())."]");
    my $template = $self->load_tmpl('error.html');
    $template->param( message => $error_msg,
                    error_msg => 'failed in runmode: '.$self->dump());
    return $template->output;
}


=head2 OTHER METHODS

=head3 get_challenge

   this function picks a random number for the user
   and uses the users secret number to calculate the key

=cut


sub get_challenge {
    my ($self) = @_;
    $self->log->info("in get_challenge()");
    my $username = $self->query->param("username");
    $self->log->info("the username (".$username.")");
    my @options = $self->authen->drivers->options;
    $self->log->info("opening file: [".($options[2])."]");
    my %UNKNOWN_USERS;
    tie(%UNKNOWN_USERS, 'NDBM_File', $options[2],  O_RDWR|O_CREAT, 0666)
       or $self->log->error( "Couldn't tie NDBM file ".($options[2])
                                                   .": $!; aborting");

    my ($num_digits, $randomA, $secretPIN);
    if ($secretPIN = $self->authen->drivers->{secretPIN}->{$username}) {
       $self->log->info("the secretPIN (".($secretPIN).")");
       #my $num_digits = length sprintf "%d", $secretPIN;
       $num_digits = length $secretPIN;
       $randomA = sprintf "%0${num_digits}d", int(rand()*10**$num_digits);
    } else { # username is unknown, we return some random length randomA
       if ((defined $UNKNOWN_USERS{$username}) &&
                   ($UNKNOWN_USERS{$username} > 3)) {
          $num_digits = $UNKNOWN_USERS{$username};
       } else {
          $num_digits = 4+int(rand()*20);
          $UNKNOWN_USERS{$username} = $num_digits;
       }
       untie %UNKNOWN_USERS;
       $randomA = sprintf "%0${num_digits}d", int(rand()*10**$num_digits);
       return "{\"randomA\": \"$randomA\"}";
    }
    $self->authen->drivers->{OneTimePIN}->{users}->{$username}->{randomA} = $randomA;
    $self->authen->username($username);
    $self->log->info("the randomA (".($randomA).")");
    my @secretArr = split('', $secretPIN);
    my @randomArr = split('', $randomA);
    my $OTP = 0;
    my $digit_sum = 0;
    for my $i (0 .. ($num_digits-1)) {
       my $digit = ($randomArr[$i] + $secretArr[$i])%10;
       $OTP += $digit;
    }
    $self->authen->drivers->{OneTimePIN}->{users}->{$username}->{OTP} = $OTP;
    my $client_ip = $ENV{'REMOTE_HOST'};
    my $request_path = (split /\?/, $ENV{'REQUEST_URI'})[0];
    my $href = "http://".$ENV{'HTTP_HOST'}.$request_path;
    $self->log->info("OTP (".($OTP).")");
    $self->log->info("client_ip (".($client_ip).")");
    $self->log->info("href (".($href).")");
    # my $signature = sha256_hex($username.$randomA.$OTP);
    # my $signature = md5_hex("$username:$client_ip:$href:$OTP");
    return "{\"randomA\": \"$randomA\"}";
}

=head3 enc_req

   this function receives an encrypted request,
   decrypts it using AES and the OTP and
   sends an encrypted reply

=cut

sub enc_req {
    my ($self) = @_;
    $self->log->info("in enc_req()");
    my $DATA = $self->query->param("DATA");
    my $username = $self->query->param("username");
    $DATA =~ s/[#]/\+/g;
    $DATA = decode_base64($DATA);
    $self->log->info("DATA: [".$DATA."]");
    my $OTP = $self->authen->drivers->{OneTimePIN}->{users}->{$username}->{OTP};
    my $hashed_otp = uc(sha256_hex($OTP));
    $self->log->info("OTP: [".$hashed_otp."]");
#    var key = CryptoJS.EvpKDF(password, salt, { keySize: 8 });
#    my $c = Crypt::Cipher::AES->new(md5_hex($OTP));

    my $c = Crypt::CBC->new( -key    => $hashed_otp,
                             -cipher => 'Cipher::AES',
                           );

    my $plaintext = $c->decrypt($DATA);
    $self->log->info("the plaintext [".$plaintext."]");
    my $req_json = decode_json $plaintext;
    $self->log->info("the json [".(Dumper %{$req_json})."]");
    if ($req_json->{"get"} eq "password_field") { 
       my $template = $self->load_tmpl('password_field.html');
       # my $options = @{$self->authen->drivers->options}[1];
       my @options = $self->authen->drivers->options;
       $self->log->info("options: [".($options[1])."]");
       my $filename = $options[1].$username.'.jpeg';
       $self->log->info("opening avatar img: [".$filename."]");
       open (my $img_fh, '<', $filename)
       or $self->log->error("couldn't open avatar img: [".$filename."]");
       my $img = do { local $/; <$img_fh> };
       close $img_fh;
       $template->param( avatar_b64 => encode_base64 $img );
       my $rsp = encode_base64($c->encrypt($template->output));
       return $rsp;
    }

}


=pod

TODO: Other methods in your public interface go here.

=cut

# TODO: Private methods go here. Start their names with an _ so they are skipped
# by Pod::Coverage.

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug-raw at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=raw>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<CGI::Application|CGI::Application>

=head1 THANKS

List acknowledgements here or delete this section.

=head1 AUTHOR

Raphael Wegmann, C<< <wegmann at psi.co.at> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014, Raphael Wegmann.  All rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version, or

b) the Artistic License version 1.0 or a later version.

The full text of the license can be found in the LICENSE file included
with this distribution.

=cut

1;    # End of raw

__END__

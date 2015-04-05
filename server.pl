use warnings;
use strict;
use CGI::Application::Server;
use lib 'lib';
use raw;
# use raw::Server;

my $app = raw->new(
    TMPL_PATH => './share/templates',
    PARAMS    => {

    },
);

my $server = CGI::Application::Server->new();
# my $server = raw::Server->new();
$server->document_root('./t/www');
$server->entry_points({
    '/index.cgi' => $app,
});
$server->run;

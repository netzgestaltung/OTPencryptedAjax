use warnings;
use strict;
use CGI::Application::Server;
use lib 'lib';
use raw;

my $app = raw->new(
    TMPL_PATH => './share/templates',
    PARAMS    => {

    },
);

my $server = CGI::Application::Server->new();
$server->document_root('./share/www');
$server->entry_points({
    '/index.cgi' => $app,
});
$server->run;

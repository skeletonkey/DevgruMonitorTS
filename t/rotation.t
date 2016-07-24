#!perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::Mock::Simple;
use Test::More tests => 5;

use Devgru::Monitor;

use_ok( 'Devgru::Monitor::TS' ) || print "Bail out!\n";

my $resp_mock    = Test::Mock::Simple->new(module => 'HTTP::Response');
my $lwp_mock     = Test::Mock::Simple->new(module => 'LWP::UserAgent');
my $response_obj = HTTP::Response->new();
$lwp_mock->add(request => sub { return $response_obj; });

my %args = (
    node_data => {
        'arg1.arg2' => {
            template_vars => [qw(arg1 arg2)],
        },
    },
    type => 'TS',
    up_frequency => 300,
    down_frequency => 60,
    down_confirm_count => 2,
    version_frequency => 86400,
    severity_thresholds => [ 25 ],
    check_timeout => 5,
    base_template => '%s.%s.com',
    end_point_template => 'http://%s/end_point',
);
my $monitor = Devgru::Monitor->new(%args);
my $node = $monitor->get_node('arg1.arg2');

$resp_mock->add(is_success => sub { return 1; });
is($monitor->_is_node_in_rotation($node), 1, 'Node is in rotation');
is($monitor->_is_cluster_in_rotation($node), 0, 'Cluster is out of rotation');

$resp_mock->add(is_success => sub { return 0; });
is($monitor->_is_node_in_rotation($node), 0, 'Node is out of rotation');
is($monitor->_is_cluster_in_rotation($node), 1, 'Cluster is in rotation');

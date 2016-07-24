#!perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::Mock::Simple;
use Test::More tests => 23;

use Devgru::Monitor;

use_ok( 'Devgru::Monitor::TS' ) || print "Bail out!\n";

my $resp_mock = Test::Mock::Simple->new(module => 'HTTP::Response');
my $response_obj = HTTP::Response->new();
my $lwp_mock  = Test::Mock::Simple->new(module => 'LWP::UserAgent');
$lwp_mock->add(request => sub { return $response_obj; });
my $ts_mock = Test::Mock::Simple->new(module => 'Devgru::Monitor::TS');
$ts_mock->add(_is_node_in_rotation => sub { return 1; });
$ts_mock->add(_is_cluster_in_rotation => sub { return 1; });

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
$resp_mock->add(content    => sub { return q+<HTML><HEAD><TITLE>TM Health Check</TITLE></HEAD><BODY> Success on Atlas, cache, Offering, Oracle and manual file tests.  </BODY></HTML>+; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_UP, 'Node is up');
is($node->status, Devgru::Monitor->SERVER_UP, 'Node has correct status');
is($node->fail_reason, '', 'Fail reason is blank');
is($node->down_count, 0, 'Down Count is 0');


my $fail_reason = 'Something failed on Atlas, cache, Offering, Oracle and manual file tests.';
$resp_mock->add(content    => sub { return qq+<HTML><HEAD><TITLE>TM Health Check</TITLE></HEAD><BODY>$fail_reason</BODY></HTML>+; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_UNSTABLE, 'Node is unstable');
is($node->status, Devgru::Monitor->SERVER_UNSTABLE, 'Node has correct status');
is($node->fail_reason, $fail_reason, 'Fail reason is correct');
is($node->down_count, 1, 'Down Count is 1');

$resp_mock->add(is_success => sub { return 0;  });
$resp_mock->add(content    => sub { return ''; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_DOWN, 'Node is down');
is($node->status, Devgru::Monitor->SERVER_DOWN, 'Node has correct status');
is($node->fail_reason, '', 'Fail reason is blank');
is($node->down_count, 2, 'Down Count is 2');

$ts_mock->add(_is_node_in_rotation => sub { return 0; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_UP, 'Node is up because of node out of rotation');
is($node->status, Devgru::Monitor->SERVER_UP, 'Node has correct status');
is($node->fail_reason, '', 'Fail reason is blank');
is($node->down_count, 0, 'Down Count is 0');

$ts_mock->add(_is_cluster_in_rotation => sub { return 0; });
is($monitor->_check_node('arg1.arg2'), Devgru::Monitor->SERVER_UP, 'Node is up because of node and cluster out of rotation');
is($node->status, Devgru::Monitor->SERVER_UP, 'Node has correct status');
is($node->fail_reason, '', 'Fail reason is blank');
is($node->down_count, 0, 'Down Count is 0');

cmp_deeply([$monitor->version_report], [], 'Empty version report');

throws_ok { $monitor->_check_node() } qr/^No node name provided to _check_node/, 'No node name provided';

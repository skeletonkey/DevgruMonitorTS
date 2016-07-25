#!perl

use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::Mock::Simple;
use Test::More tests => 5;

use Devgru::Monitor;

use_ok( 'Devgru::Monitor::TS' ) || print "Bail out!\n";

my $ts_mock      = Test::Mock::Simple->new(module => 'Devgru::Monitor::TS');
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
$ts_mock->add(_ssh => sub { return q+  File: `/app/shared/conf/fail_cluster'
  Size: 0         	Blocks: 0          IO Block: 32768  regular empty file
Device: 15h/21d	Inode: 26685106    Links: 1
Access: (0664/-rw-rw-r--)  Uid: ( 1141/   tmweb)   Gid: ( 1014/   tmweb)
Access: 2016-07-25 08:56:43.313713000 -0700
Modify: 2016-07-25 08:56:43.313713000 -0700
Change: 2016-07-25 08:56:43.313713000 -0700
+; });
is($monitor->_is_node_in_rotation($node), 1, 'Node is in rotation');
is($monitor->_is_cluster_in_rotation($node), 1, 'Cluster is in rotation');

$ts_mock->add(_ssh => sub { return q+stat: cannot stat `/app/shared/conf/fail_cluster': No such file or directory
+; });
$resp_mock->add(is_success => sub { return 0; });
is($monitor->_is_node_in_rotation($node), 0, 'Node is out of rotation');
is($monitor->_is_cluster_in_rotation($node), 0, 'Cluster is out of rotation');

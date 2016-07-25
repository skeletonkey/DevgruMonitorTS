package Devgru::Monitor::TS;

use 5.006;
use strict;
use warnings;

use parent qw(Devgru::Monitor);

use Carp;

=head1 NAME

Devgru::Monitor::TS - Ticketing Services Nodes monitor

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

my $NODE_IN_ROTATION_FILE        = 'netscaler_test_object';
#my $CLUSTER_OUT_OF_ROTATION_FILE = 'akamai_test_object';
my $CLUSTER_OUT_OF_ROTATION_FILE = '/app/shared/conf/fail_cluster';
my $SSH_USER                     = 'tmweb';

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 _check_node

Connect to the nodes endpoint (healthcheck) and record what was found.

Checks to see if the node is out of rotations by checking for the lack of a 
netscaler_test_object file.

Checks to see if the cluster is out of rotation by checking for the existance
of akamai_test_object file.

=cut

sub _check_node {
    my $self = shift;
    my $node_name = shift || croak("No node name provided to _check_node");

    my $ua = LWP::UserAgent->new();
    $ua->timeout($self->check_timeout);
    $ua->agent(__PACKAGE__ . '/' . $VERSION);

    my $node = $self->get_node($node_name);

    my $req = HTTP::Request->new(GET => $node->end_point);
    my $res = $ua->request($req);

    my $status = $self->SERVER_DOWN; # server is down
    $node->fail_reason('');
    if ($res->is_success) {
        if (my $content = $res->content) {
            if ($content =~ /Success on /) {
                $status = $self->SERVER_UP;
                $node->down_count(0);
            }
            else {
                $status = $self->SERVER_UNSTABLE;
                my ($body) = $content =~ /<BODY>(.+?)<\/BODY>/;
                $node->fail_reason($body);
                $node->inc_down_count;
            }
        }
    }
    else {
        if ($self->_is_node_in_rotation($node) && $self->_is_cluster_in_rotation($node)) {
            $status = $self->SERVER_DOWN;
            $node->inc_down_count;
        }
        else {
            $status = $self->SERVER_UP;
            $node->down_count(0);
        }
    }

    $node->status($status);
    return $status;
}

sub version_report {
    return ();
}

=head2

If the file $NODE_IN_ROTATION_FILE exists then the node is in rotation.

=cut
sub _is_node_in_rotation {
    my $self = shift;
    my $node = shift;

    my $node_in = 0;
    
    my $end_point = $self->build_base_template($node->template_vars) . '/' . $NODE_IN_ROTATION_FILE;

    my $ua = LWP::UserAgent->new();
    $ua->timeout($self->check_timeout);
    $ua->agent(__PACKAGE__ . '/' . $VERSION);

    my $req = HTTP::Request->new(GET => $end_point);
    my $res = $ua->request($req);

    $node_in = 1 if $res->is_success;

    return $node_in;
}

=head2

If the file $CLUSTER_OUT_OF_ROTATION_FILE exists then the cluster is out of rotation

=cut
sub _is_cluster_in_rotation {
    my $self = shift;
    my $node = shift;

    my $cluster_in = 0;
    
    my $server_name = $self->build_base_template($node->template_vars);

    my $ret = _ssh($SSH_USER, $server_name, "stat $CLUSTER_OUT_OF_ROTATION_FILE");

    $cluster_in = 1 unless $ret =~ /No such file or directory/;

    return $cluster_in;
}

# This is here to make testing possible using mocks
sub _ssh {
    my $user   = shift || croak("No user provided to _ssh");
    my $server = shift || croak("No server provided to _ssh");
    my $cmd    = shift || croak("No cmd provided to _ssh");

    return `ssh -A -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user\@$server "$cmd"`;
}

=head1 AUTHOR

Erik Tank, C<< <tank at jundy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devgru-monitor-ts at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devgru-Monitor-TS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devgru::Monitor::TS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devgru-Monitor-TS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devgru-Monitor-TS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devgru-Monitor-TS>

=item * Search CPAN

L<http://search.cpan.org/dist/Devgru-Monitor-TS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Erik Tank.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Devgru::Monitor::TS

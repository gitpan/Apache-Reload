# $Id: Reload.pm,v 1.4 2000/08/12 16:12:28 matt Exp $

package Apache::Reload;

use strict;

$Apache::Reload::VERSION = '0.02';

my %Stat = ($INC{"Apache/Reload.pm"} => time);
my %INCS;

sub import {
	my $class = shift;
	my ($package,$file) = (caller)[0,1];
	$package =~ s/::/\//g;
	$package .= ".pm";
	
#	warn "Apache::Reload: $package loaded me\n";
	
	if (grep /^off$/, @_) {
		delete $INCS{$package};
	}
	else {
		$INCS{$package} = $file;
	}
}

sub handler {
	my $r = shift;
	
	my $DEBUG = ref($r) && (lc($r->dir_config("ReloadDebug") || '') eq 'on');
	
	if (ref($r) && (lc($r->dir_config("ReloadAll") || 'on') eq 'on')) {
		*Apache::Reload::INCS = \%INC;
	}
	else {
		*Apache::Reload::INCS = \%INCS;
	}
	
	while (my($key, $file) = each %Apache::Reload::INCS) {
		local $^W;
#		warn "Apache::Reload: Checking mtime of $key\n" if $DEBUG;
		
		my $mtime = (stat $file)[9];
		warn("Apache::Reload: Can't locate $file\n"),next 
				unless defined $mtime and $mtime;
		
		unless (defined $Stat{$file}) {
			$Stat{$file} = $^T;
		}
		
		if ($mtime > $Stat{$file}) {
			delete $INC{$key};
			require $key;
			warn("Apache::Reload: process $$ reloading $key\n")
					if $DEBUG;
		}
		$Stat{$file} = $mtime;
	}
	
	return 1;
}

1;
__END__

=head1 NAME

Apache::Reload - Reload this module on each request (if modified)

=head1 SYNOPSIS

In httpd.conf:

  PerlInitHandler Apache::Reload
  PerlSetVar ReloadAll Off

Then your module:

  package My::Apache::Module;

  use Apache::Reload;
  
  sub handler { ... }
  
  1;

=head1 DESCRIPTION

This module is two things. First it is an adaptation of Randall 
Schwartz's Stonehenge::Reload module that attempts to be a little 
more intuitive and makes the usage easier. Stonehenge::Reload was
written by Randall to make specific modules reload themselves when
they changed. Unlike Apache::StatINC, Stonehenge::Reload only checked
the change time of modules that registered themselves with 
Stonehenge::Reload, thus reducing stat() calls. Apache::Reload also
offers the exact same functionality as Apache::StatINC, and is thus
designed to be a drop-in replacement. Apache::Reload only checks modules
that register themselves with Apache::Reload if you explicitly turn off
the StatINC emulation method (see below). Like Apache::StatINC,
Apache::Reload must be installed as an Init Handler.

To use as a StatINC replacement, simply add the following configuration
to your httpd.conf:

  PerlInitHandler Apache::Reload

To only reload modules that have explicitly registered with Apache::Reload,
add the following to the httpd.conf:

  PerlInitHandler Apache::Reload
  PerlSetVar ReloadAll Off
  # ReloadAll defaults to On

If you want to temporarily turn off reloading of a module (which is 
slightly problematic since it won't happen until the next hit on the
same server because of the way this thing works, and won't start 
reloading again until you restart the server) you can use the 'off'
option (this only works when ReloadAll is Off):

  use Apache::Reload 'off';

Obviously you wouldn't do that generally, but it can be useful if you 
intend to make large changes to a particular module whilst the server 
is running, and still be able to test it compiles with perl -wc, without
worrying about the server reloading it.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

Apache::StatINC, Stonehenge::Reload

=cut

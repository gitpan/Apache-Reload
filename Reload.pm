# $Id: Reload.pm,v 1.3 2000/08/11 20:29:38 matt Exp $

package Apache::Reload;

use strict;

$Apache::Reload::VERSION = '0.01';

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
	
	while (my($key, $file) = each %INCS) {
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

  PerlInitHandler Apache::StatINC

Then your module:

  package My::Apache::Module;

  use Apache::Reload;
  
  sub handler { ... }
  
  1;

=head1 DESCRIPTION

This module is an adaptation of Randall Schwartz's Stonehenge::Reload
module that attempts to be a little more intuitive and makes the usage
easier. Like Apache::StatINC it must be installed as an Init Handler,
but unlike StatINC it must also be used by the module you want reloading.

If you want to temporarily turn off reloading of a module (which is 
slightly problematic since it won't happen until the next hit on the
same server because of the way this thing works) you can use the 'off'
option:

  use Apache::Reload 'off';

Obviously you wouldn't do that generally, but it can be useful if you 
intend to make large changes to a particular module.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

Apache::StatINC, Stonehenge::Reload

=cut

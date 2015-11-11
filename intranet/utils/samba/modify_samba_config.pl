#!/usr/bin/perl
use strict;
use warnings;

######################################################################
##
##  Simple add/delete/change share command script for Samba
##
##  Copyright (C) Gerald Carter                2004
##                Michal Růžička               2012
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, see <http://www.gnu.org/licenses/>.
##
######################################################################

use File::Basename;
use File::Spec;
use File::Copy;
use File::Temp qw(tempfile);
use Fcntl qw(:flock SEEK_SET);

## check for correct parameters
unless (@ARGV >= 2 && @ARGV <= 5) {
	print(STDERR "Usage: $0 <configfile> <share> [<path>] [<comment>] [<max connections>]\n");
	exit(1);
}

my $configfile = GetShareConfigFileName($ARGV[0]);
my $writefh;

open($writefh, '+<', $configfile)
	or die("Unable to open $configfile: $!\n");

flock($writefh, LOCK_EX)
	or die("Cannot lock $configfile: $!\n");

my $backupconfigfile = $configfile . '.bak';
my $readfh = WriteBackupConfigFile($writefh, $backupconfigfile);
my $config = ReadConfigFile($readfh);

($readfh == $writefh)
	or close($readfh);

my $result;
## we have the configuration in our hash of hashes now; add or delete the specified section
if (@ARGV > 2) {
	@{$$config{$ARGV[1]}}{('path', 'comment', 'max connections')[0 .. @ARGV-3]} = @ARGV[2 .. @ARGV-1];
	$result = 1;
}
else {
	$result = defined(delete($$config{$ARGV[1]}));
}

truncate($writefh, 0);
seek($writefh, 0, SEEK_SET);

WriteConfigFile($writefh, $config);

close($writefh);
unlink($backupconfigfile);

($result)
	or die("Share not present: $ARGV[1]\n");
exit(0);


#######################################################################################
## WriteBackupConfigFile()
##
sub WriteBackupConfigFile {
	my ($fh, $backupconfigfile) = @_;

	if (-f $backupconfigfile && -r $backupconfigfile) {
		$fh = undef;
		open($fh, '<', $backupconfigfile)
			or die("Unable to open $backupconfigfile: $!\n");
	}
	else {
		my ($writefh, $tempfilename) = tempfile(basename($backupconfigfile) . '.XXXXXXXXXX', DIR => dirname($backupconfigfile));
		copy($fh, $writefh)
			or die("Unable to write $tempfilename: $!\n");
		seek($fh, 0, SEEK_SET);
		close($writefh);
		rename($tempfilename, $backupconfigfile)
			or die("Unable to rename $tempfilename to $backupconfigfile: $!\n");
	}

	$fh;
}

#######################################################################################
## ReadConfigFile()
##
sub ReadConfigFile {
	my ($fh) = @_;

	my $config = {};
	my ($section, $param, $value);

	## FIXME!!  Right now we throw away all comments in the file.
	while (<$fh>) {
		chomp();

		## eat leading whitespace
		s/^\s+//;

		## eat trailing whitespace
		s/\s+$//;

		## throw away comments
		next if /^[#;]/;

		## set the current section name for storing the hash
		if (/^\[(.*)\]$/) {
			if (length($1)) {
				$section = $1;
			}
			else {
				die("Empty section name\n");
			}

			next;
		}

		## check for a param = value
		if (/=/) {
			($param, $value) = split(/=/, $_, 2);
			$param =~ s/^\s+//;
			$param =~ s/\s+$//;
			$param =~ s/\s{2,}/ /g;
			$param = lc($param);

			$value =~ s/^\s+//;

			$$config{$section}{$param} = $value;
		}
	}

	$config;
}

#######################################################################################
## WriteConfigFile()
##
sub WriteConfigFile {
	my ($fh, $config) = @_;

	## print the file back out, beginning with the global section
	print($fh "#\n# Generated by $0\n#\n");

	if (exists($$config{'global'})) {
		WriteSection($fh, 'global', delete($$config{'global'}));
	}

	foreach my $section (sort keys %$config) {
		print($fh "## Section - [$section]\n");
		WriteSection($fh, $section, delete($$config{$section}));
	}

	print($fh "#\n# end of generated configuration\n#\n");
}

#######################################################################################
## WriteSection()
##
sub WriteSection {
	my ($fh, $name, $section) = @_;

	print($fh "[$name]\n");
	(exists($$section{'max connections'}) && $$section{'max connections'} == 0)
		and delete($$section{'max connections'});
	foreach my $param (sort keys %$section) {
		print($fh "\t$param".' 'x(25-length($param)). " = $$section{$param}\n");
	}
	print($fh "\n");
}

#######################################################################################
## GetShareConfigFileName()
##
sub GetShareConfigFileName {
	my ($configfile) = @_;
	my @parsed_name = fileparse($configfile, qr/\.[^.]*/);

	## if fileneme is empty and extension is not then treat the extension as a file name
	(length($parsed_name[0]) == 0 && length($parsed_name[2]) > 0)
		and @parsed_name[0,2] = @parsed_name[2,0];

	File::Spec->catfile($parsed_name[1], $parsed_name[0] . '-shares' . $parsed_name[2]);
}

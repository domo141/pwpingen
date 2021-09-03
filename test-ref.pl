#!/usr/bin/perl
# -*- mode: cperl; cperl-indent-level: 4 -*-
# $ test-ref.pl $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2021 Tomi Ollila
#	    All rights reserved
#
# Created: Sat 14 Aug 2021 22:16:34 EEST too
# Last modified: Thu 02 Sep 2021 16:44:30 +0300 too

# runs ./pwpingen-ref and ./pwpingen-cli.py 1000 times with various
# sets of arguments and compare results (expect same w/ same args)

use 5.8.1;
use strict;
use warnings;

$ENV{'PATH'} = '/sbin:/usr/sbin:/bin:/usr/bin';

die "'./pwpingen-ref' does not exist. execute 'sh pwpingen-ref.c' first\n"
  unless -x 'pwpingen-ref';

my ($da, $db);
for my $r (1..1000) {
    my $n = int(rand(8)) + 1;
    my @al;
    print "$r $n";
    for my $a (1..$n) {
	my $l = int(rand(160)) + 1;
	print " - $a $l";
	my $s = '';
	$s = $s . crypt rand, rand(100) while (length $s < $l);
	push @al, substr $s, -$l;
    }
    print "\n";
    open I, '-|', './pwpingen-ref', @al;    read I, $da, 1024; close I or die;
    open I, '-|', './pwpingen-cli.py', @al; read I, $db, 1024; close I or die;
    #print $da, $db;
    die if $da ne $db;
}
print "output of 1000th run:\n";
print $da, "-\n", $db;

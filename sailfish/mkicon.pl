#!/usr/bin/perl
# -*- mode: cperl; cperl-indent-level: 4 -*-
# $ mkpohja.pl $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2021 Tomi Ollila
#	    All rights reserved
#
# Created: Sun 15 Aug 2021 15:17:41 EEST too
# Last modified: Sun 29 Aug 2021 17:21:01 +0300 too

use 5.8.1;
use strict;
use warnings;

$ENV{'PATH'} = '/no//path/';

# python PIL failed to do ellipse with exact width & height
# given by bounding box, so have to hack oneself :/
# perhaps I now know why, but doing this is fun anyway...

# w/ constant, same ref is always returned. sub c () { [ ... ] } returns new...
use constant
{
 oooo  => [   0,   0,   0,   0 ],
 Black => [   0,   0,   0, 255 ],
 White => [ 255, 255, 255, 255 ],
 Red   => [ 255,   0,   0, 255 ],
 Green => [   0, 255,   0, 255 ],
 Blue  => [   0,   0, 255, 255 ],
 Brown => [ 165,  42,  42, 255 ]
};

my @pa; push @pa, [ (oooo) x 344 ] foreach (1..344);
#my @pa; push @pa, [ ([0,0,0,0]) x 344 ] foreach (1..344);

# test line: half-alpha black background (from full alpha)
#$pa[0][0][3] = 127; # works with (oooo) x 344 case

# while White is constant, the array behind ref can be modified (but don't :)
#my $x = White; $x->[2] = 0;

for my $r (1..170) {
    for (1..629) { # with 1 no sin nor cos get value of 1
	my $xd = int(cos($_/400) * $r);
	my $yd = int(sin($_/400) * $r);
	#$pa[171 - $yd][171 - $xd] = White;
	$pa[171 - $yd][172 + $xd] = Black;
	$pa[172 + $yd][171 - $xd] = Black;
	#$pa[172 + $yd][172 + $xd] = White;
    }
}

for my $i (6..171) {
    for (2..171) {
	$pa[$_][$i] = Black;
	$pa[$i][$_] = Black;

	$pa[166 + $i][343 - $_] = Black;
	$pa[343 - $_][166 + $i] = Black;
    }
}

for my $i (2..170) {
    #next unless $i & 2;
    #my $r = 140 - sqrt($i*100);
    #my $g = 140 - sqrt($i*100);
    my $r = sqrt($i * 100);
    my $g = sqrt($i * 100);
    my $b = 40 + sqrt($i*60);
    #print "$i $r $g $b\n";
    for (0..$i+1) {
	my ($o, $p) = ($i - $_, $i + $_);

	my $v = [ 130, $g, $b, 255 ];
	$pa[$o][$p] = $v if $pa[$o][$p][3] > 127;
	$pa[$p][$o] = $v if $pa[$p][$o][3] > 127;
	$pa[$o+1][$p] = $v if $pa[$o+1][$p][3] > 127;
	$pa[$p+1][$o] = $v if $pa[$p+1][$o][3] > 127;

	my $w = [ $r, 130, $b, 255 ];
	$o = 340 - $o;
	$p = 340 - $p;
	$pa[$o][$p] = $w if $pa[$o][$p][3] > 127;
	$pa[$p][$o] = $w if $pa[$p][$o][3] > 127;
	$pa[$o+1][$p] = $w if $pa[$o+1][$p][3] > 127;
	$pa[$p+1][$o] = $w if $pa[$p+1][$o][3] > 127;
    }
}

# from /usr/share/X11/rgb.txt
#250 235 215             AntiqueWhite
#255 239 219             AntiqueWhite1
#238 223 204             AntiqueWhite2
#205 192 176             AntiqueWhite3
#139 131 120             AntiqueWhite4

#center circle
if (1) {
    #my $rgba = [ 250, 235, 215, 255 ];
    #my $rgba = [ 205, 192, 176, 255 ];
    my $rgbb = [ 205, 192, 176, 255 ];
    #my $rgbc = [ 164, 153, 140, 255 ];
    #my $rgbc = [ 184, 172, 158, 255 ];
    # if differed, would have "scanlines"
    my $rgbc = [ 205, 192, 176, 255 ];
    #my $rgbb = White;
    #my $rgbc = [ 169, 169, 169, 255 ];
for my $r (0..99) {
    for (1..629) { # with 1 no sin nor cos get value of 1
	my $xd = int(cos($_/400) * $r);
	my $yd = int(sin($_/400) * $r);
	my $y2 = $yd + 4;
	my $rgba = (($yd >> 2) % 3)? $rgbb: $rgbc;
	my $rgbd = (($y2 >> 2) % 3)? $rgbb: $rgbc;
	$pa[171 - $yd][171 - $xd] = $rgba;
	$pa[171 - $yd][172 + $xd] = $rgba;
	$pa[172 + $yd][171 - $xd] = $rgbd;
	$pa[172 + $yd][172 + $xd] = $rgbd;
    }
}}


my %hash;
while (<DATA>) {
    if (/^(\S)/) {
	my $key = $1;
	my @lines;
	while (<DATA>) {
	    last if /^\s*$/;
	    chomp;
	    push @lines, $_;
	}
	$hash{$key} = \@lines;
    }
}

sub kirjain($$$$)
{
    my ($x, $y, $k, $c) = @_;
    $k = $hash{$k} or die;
    # almost invisible "scanline" emulation...
    my $d = [ $c->[0]*.8, $c->[1]*.8, $c->[2]*.8, 255 ];
    my $i = 3;
    foreach (@{$k}) {
	my $x = $x;
	my $e = ($i++ % 3)? $c: $d;
	foreach (split '', $_) {
	    if ($_ eq '#') {
		for ($x..$x+3) {
		    $pa[$y+0][$_] = $e;
		    $pa[$y+1][$_] = $e;
		    $pa[$y+2][$_] = $e;
		    $pa[$y+3][$_] = $e;
		}
	    }
	    $x += 4;
	}
	$y += 4;
	#print $_, "\n";
    }
}

kirjain  16, 12, 'p', Green;
kirjain  44, 12, 'w', Green;
kirjain  72, 12, 'p', Green;
kirjain 100,  8, 'i', Green;
kirjain 128, 12, 'n', Green;

#kirjain 220, 240, '=', White;
kirjain 248, 240, 'r', White;
kirjain 276, 240, '4', White;
kirjain 304, 240, 'z', White;

kirjain 220, 292, '6', White;
kirjain 248, 292, '4', White;
kirjain 276, 292, '8', White;
kirjain 304, 292, '7', White;


sub nelio($$$)
{
    my ($x, $y, $w) = @_;
    $x -= $w / 2; $y -= $w / 2;
    $w -= 1;
    for (1..4) {
	for (0..$w) {
	    $pa[$y + $_][$x] = Black;
	    $pa[$y][$x + $_] = Black;

	    $pa[$y + $_][$x + $w] = Black;
	    $pa[$y + $w][$x + $_] = Black;
	}
	$w -= 2; $y += 1; $x += 1;
    }
}

my ($L, $K, $P) = (128, 216, 64);

nelio $L, $L, $P; nelio $K, $K, $P;
nelio $L, $K, $P; nelio $K, $L, $P;

kirjain 204, 108, '1', Black;
kirjain 116, 108, '0', Black;

kirjain 204, 196, '0', Black;
kirjain 116, 196, '1', Black;

sub viiva($$$$)
{
    my ($x1,$y1,$x2,$y2) = @_;
    my $adv = ($x2-$x1)/($y2-$y1);
    #print $adv, "\n";
    for($y1..$y2) {
	$pa[$_][$x1+0] = Black;
	$pa[$_][$x1+1] = Black;
	$pa[$_][$x1+2] = Black;
	$pa[$_][$x1+3] = Black;
	if ($adv) {
	    $pa[$_][$x1+4] = Black;
	    $pa[$_][$x1+5] = Black;
	    $pa[$_][$x1+6] = Black;
	    $pa[$_][$x1+7] = Black;
	    $x1 += $adv;
	}
    }
}

viiva 124,80, 124,96;
viiva 132,64, 196,96;

viiva 140,156, 196,184;
viiva 196,156, 140,184;

viiva 216,244, 216,268;

viiva 140,244, 204,276;

# outer circle
if (1) {
    #my $rgba = [ 130, 130, 170, 255 ];
    my $rgba = [ 0, 0, 0, 255 ];
for my $r (97..128) {
#for my $r (1..128) {
    for (1..629) { # with 1 no sin nor cos get value of 1
	my $xd = int(cos($_/400) * $r);
	my $yd = int(sin($_/400) * $r);
	$pa[171 - $yd][171 - $xd] = $rgba;
	$pa[171 - $yd][172 + $xd] = $rgba;
	$pa[172 + $yd][171 - $xd] = $rgba;
	$pa[172 + $yd][172 + $xd] = $rgba;
    }
}}

open O, '>', 'icon344.wip';

my ($width, $height) = (344, 344);

my $size = $width * $height * 4;

# bmp header:        wh     s    rgba
print O pack 'ccVx4VVVVcxcxVVVVx8VVVVccccx48',
  0x42, 0x4d, 122 + $size, 122, 108, $width, $height, 1, 32, 3, $size,
  2835, 2835, 0xff, 0xff << 8, 0xff << 16, 0xff << 24, 0x20, 0x6e, 0x69, 0x57;

foreach (reverse @pa) {
    foreach (@$_) {
	print O pack 'CCCC', @$_;
    }
}
close O or die;

rename 'icon344.wip', 'icon344.bmp';
print "Wrote 'icon344.bmp'\n";

__DATA__


0
  ##
 ####
##  ##
##  ##
## ###
### ##
##  ##
##  ##
 ####
  ##


1
   #
  ##
 ###
####
  ##
  ##
  ##
  ##
  ##
######


4
   ##
  ###
 ####
 ####
## ##
## ##
######
######
   ##
   ##


6
 ####
######
##  ##
##
#####
######
##  ##
##  ##
######
 ####


7
######
######
   ##
   ##
  ##
  ##
 ##
 ##
##
##


8
 ####
######
##  ##
##  ##
 ####
 ####
##  ##
##  ##
######
 ####


c
.
.
 ####
######
##  ##
##
##
##  ##
######
 ####


i
  ##
  ##
.
 ###
 ###
  ##
  ##
  ##
  ##
 ####
 ####


n
.
.
# ###
######
### ##
##  ##
##  ##
##  ##
##  ##
##  ##


p
.
.
# ###
######
##  ##
##  ##
##  ##
######
## ##
##
##
##

r
.
.
# ###
######
###  #
##
##
##
##
##


w
.
.
##  ##
##  ##
##  ##
##  ##
######
######
######
##  ##

z
.
.
######
######
    ##
  ###
 ###
##
######
######

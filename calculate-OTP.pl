#!/usr/bin/perl

use Data::Dumper qw/Dumper/;
use Term::ReadKey;
use strict;

print "enter challenge:";
my $challenge = ReadLine(0);
chomp $challenge;
print "enter secret PIN:";
ReadMode('noecho');
my $pin = ReadLine(0);
ReadMode 0;
chomp $pin;

print "\n";
my $num_digits = length $pin;
my @secretArr = split('', $pin);
my @randomArr = split('', $challenge);
my $OTP = 0;
for my $i (0 .. ($num_digits-1)) {
   my $digit = ($randomArr[$i] + $secretArr[$i])%10;
   $OTP += $digit;
}

print "OTP: $OTP\n";


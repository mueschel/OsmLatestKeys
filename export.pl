#!/usr/bin/perl
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Storable qw(store retrieve);
use POSIX qw(strftime);
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
use JSON;
use LWP::UserAgent;
use Encode qw(encode);
use Data::Dumper;

my $isserver = 0;
my $date = time();
my $datestring = strftime("%Y-%m-%d %H:%M",localtime($date));

my  $d = retrieve("data/storage.pstore");

      local $Data::Dumper::Purity = 1;
  print Dumper $d;

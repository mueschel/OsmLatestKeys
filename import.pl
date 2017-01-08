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

my $VAR1;
$VAR1 = do('dump.pl');
my $d = $VAR1;

store($d,"data/storage.pstore");  
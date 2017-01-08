#!/usr/bin/perl
use warnings;
use strict;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Storable qw(store retrieve);
use POSIX qw(strftime);
use utf8;
binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
use JSON;
use LWP::UserAgent;
use Encode qw(encode);
use URI::Encode qw(uri_encode);
use Data::Dumper;


my $isserver = 0;
my $date = time();
my $datestring = strftime("%Y-%m-%d %H:%M",localtime($date));

print "Content-Type: text/html; charset=utf-8\r\n\r\n" if $isserver;
print <<"HDOC";
<!DOCTYPE html>
<html lang="en">
<head>
 <title>OSM Latest Keys</title>
 <link rel="stylesheet" type="text/css" href="../lanes/style.css">
 <link rel="stylesheet" type="text/css" href="./style.css">
 <meta  charset="UTF-8"/>
 <base target="_blank">
</head>
<body>
<h1>List of keys recently appearing in OSM</h1>
<p>Source of data: <a href="http://taginfo.openstreetmap.org">TagInfo</a>. Click on a key to get additional information from TagInfo.
<p>If using information from this page to make changes to the OSM database - please keep in mind the usual guidelines: 
No mechanical edits, no changes without checking validity of tags, inform the original mapper politely, 
don't delete any relevant information...

<p>Last update of this file: $datestring
HDOC

my $d;
if(-e "data/storage.pstore") {
  system("cp data/storage.pstore data/storage$date.pstore");
  $d = retrieve("data/storage.pstore");
  }

#Load new data from Taginfo API, if last update is older than one day
if($d->{'lastchange'} < $date - 30000) {
  print "Loading new data... (this might take a while, be patient!\n" if $isserver;
  my $ua      = LWP::UserAgent->new();
  my $request = $ua->get("http://taginfo.openstreetmap.org/api/4/keys/all"); 
  my $n = decode_json($request->content());
  
  print "Processing new data...\n" if $isserver;
  foreach my $k (@{$n->{data}}) {
    $d->{k}{$k->{'key'}}{num} = $k->{'count_all'};
    if (!defined $d->{k}{$k->{'key'}}{lastseen} || $d->{k}{$k->{'key'}}{lastseen} != $d->{'lastchange'}) { #reset firstseen if not in last extract
      $d->{k}{$k->{'key'}}{firstseen} = $date;
      }
    $d->{k}{$k->{'key'}}{lastseen} = $date;
    }

  $d->{'lastchange'} = $date;  
  store($d,"data/storage.pstore");  
  }

my @list;  

foreach my $k (keys %{$d->{k}}) {
  if($d->{k}{$k}{firstseen} >= $date - 50000){
    push(@list,$k);
    }
  }


#Print table, sorted by date of appearance and alphabetic  
print "<table><th>Key<th>Count<th>FirstSeen<th>LastSeen<th>Editor\n";  
foreach my $k (sort { $d->{k}{$b}{firstseen} cmp $d->{k}{$a}{firstseen} || lc($a) cmp lc($b) } keys %{$d->{k}}) {
  if($d->{k}{$k}{firstseen} >= $d->{'lastchange'} - 4000000 && $d->{k}{$k}{num} != 0){
    my $seen = strftime('%Y-%m-%d',localtime($d->{k}{$k}{firstseen}));
    
    my $lastseen = "";
       $lastseen = strftime('%Y-%m-%d',localtime($d->{k}{$k}{lastseen})) if $d->{k}{$k}{lastseen} != $d->{'lastchange'};
    my $num = '';
       $num = $d->{k}{$k}{num} if $lastseen eq "";

    next unless($lastseen eq "" || $d->{k}{$k}{lastseen} >= $d->{'lastchange'} - 600000);
    
    my $lurl = uri_encode("[out:xml];(node[\"$k\"];way[\"$k\"];>;rel[\"$k\"];);out meta;",{ encode_reserved => 1, double_encode => 1 } );
    $lurl = uri_encode("http://overpass-api.de/api/interpreter?data=".$lurl,{ encode_reserved => 1, double_encode => 1 } );
    $lurl = "http://level0.osmz.ru/?url=".$lurl;

    my $ourl = uri_encode("[out:json];(node[\"$k\"];way[\"$k\"];>;rel[\"$k\"];);out meta;",{ encode_reserved => 1, double_encode => 1 } );
    $ourl = "http://overpass-turbo.eu/?Q=".$ourl;

    my $jurl = uri_encode($k.'=');
    $jurl = "http://overpass-api.de/api/xapi_meta?*[$jurl*]";
    $jurl = "http://localhost:8111/import?url=".$jurl;

    print("<tr><td>") if $lastseen eq "";
    print("<tr class=\"removed\"><td>") unless $lastseen eq "";
   
    print("<a href=\"http://taginfo.openstreetmap.org/keys/$k\">") if $lastseen eq "";
    print("$k");
    print("</a>") if $lastseen eq "";  
    print("<td>$num<td>$seen<td>$lastseen<td>");
    print("<a href=\"$lurl\">(L)</a>") if $lastseen eq "";
    print("<a href=\"http://taginfo.openstreetmap.org/keys/$k\">&nbsp;(T)</a>") if $lastseen eq "";
    print("<a href=\"$jurl\" target=\"hI\">&nbsp;(J)</a>") if $lastseen eq "";
    print("<a href=\"$ourl\">&nbsp;(O)</a>") if $lastseen eq "";

    print("\n");
    }
  }
print "</table>";
print '<iframe style="display: none" id="hI" name="hI"></iframe>';
print "</body></html>\n";

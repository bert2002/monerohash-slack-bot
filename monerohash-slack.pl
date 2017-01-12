#!/usr/bin/perl
# script: report to slack channel
# author: Steffen Wirth <s.wirth@itbert.de>
# notes:

use strict;
use utf8;
no warnings 'utf8';
use POSIX qw/strftime/;
use Data::Dumper; 
use Config::General;
use Getopt::Long;
use FindBin qw($Bin);
use LWP::UserAgent;
use JSON;
use IO::Socket::SSL 'inet4';

##########################
#       Settings         #
##########################

GetOptions (
	'c|conf=s' => \my $conf,
	'h|help' => \my $help
) or exit 1;

if ($help) {
	print "Usage: $Bin/$0\n";
	print "	--conf backendConfig ";
	exit;
}

my $config;
my %config = Config::General::ParseConfig(
		-ConfigFile => "$Bin/$conf",
    -IncludeRelative => 1,
    -UseApacheInclude => 1,
);

my $DEBUG = 							$config{debug};
my $LOGFILE =							$config{logfile};
my $ACCOUNT =							$config{account};
my $SLACK_URL = 					$config{slack_url};
my $SLACK_CHANNEL = 			$config{slack_channel};
my $WALLET =							$config{wallet};
my $MONEROHASH =					$config{monerohash};


# logging
mkdir "$LOGFILE", 0777 unless -d "$LOGFILE/";
open (LOGFILE, ">>$LOGFILE/monerohash-slack.log") or die "can not open logfile $LOGFILE/monerohash-slack.log";
sub mylog {
  my($error, $status) = @_;
  
	my $date = localtime;
  if ($DEBUG) {
   print "$date  $$ $error     $status\n";
  } elsif ($error != "DEBUG") {
   print LOGFILE "$date  $$ $error     $status\n";
  }
}

##########################
#          Subs          #
##########################

sub SendSlack {
	my ($message,$channel,$url) = @_;
	my $data = "{\"text\":\"$message\",\"channel\":\"$channel\",\"username\":\"MoneroBot\"}";
	my $req = HTTP::Request->new('POST', $url);
	$req->header('Content-Type' => 'application/json');
	$req->content($data);
	my $lwp = LWP::UserAgent->new;
	my $response = $lwp->request($req);
}


##########################
#         Script         #
##########################
mylog("INFO","*** start $Bin/$0 ***");

my $text = "$ACCOUNT:";
my $MINER_URL = $MONEROHASH . $WALLET;

# get miner status
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36");
my $req = HTTP::Request->new(GET => $MINER_URL);
my $response = $ua->request($req);

if ($response->is_success) {
	my $rs = decode_json($response->content);
	my $hashrate = $rs->{stats}->{'hashrate'};
	my $balance = $rs->{stats}->{'balance'};
	$balance = $balance * "0.000000000001";
	mylog("INFO","hashrate: $hashrate Balance: $balance");
	$text = "$text Hashrate: *$hashrate* Balance: *$balance*";
}

# send slack notification
my $bla = SendSlack($text,$SLACK_CHANNEL,$SLACK_URL);

mylog("INFO","*** end $Bin/$0 ***");



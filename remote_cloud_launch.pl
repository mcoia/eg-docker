#!/usr/bin/perl
use lib qw(../);
use Loghandler;
use Getopt::Long;
use Data::Dumper;

my $dbname='';
my $localusername='';
my $clustername='';

GetOptions (
"dbname=s" => \$dbname,
"localusername=s" => \$localusername,
"clustername=s" => \$clustername
)
or die("Error in command line arguments\n");

print "dbname = $dbname\nlocalusername=$localusername\nclustername=$clustername\n";


# gather up pod IPs
system("kubectl get po|grep -v NAME | awk '{print \$1}'|while read line ; do kubectl describe po/\$line ; done |grep IP | awk '{print \$2}'| tr '\\n' ' ' > /tmp/pods");
my $podfile = new Loghandler("/tmp/pods");
my @pods = @{$podfile->readFile()};

my @pod_IPS = split('\s',@pods[0]);
print Dumper(@pod_IPS);

my $sshconfig = new Loghandler("/home/$localusername/.ssh/config");
my $clusterconfig = new Loghandler("/home/$localusername/.clusterssh/clusters");

my $hostsFile = new Loghandler("/etc/hosts");
my @hostlines = @{$hostsFile->readFile()};
my @clusterconfiglines = @{$clusterconfig->readFile()};

$sshconfig->truncFile(""); 
my $loop = 0;
my $podNames='';
foreach(@pod_IPS)
{
	my $thisIP = $_;
	$sshconfig->addLine("Host $clustername"."-$loop");
	$sshconfig->addLine("  ProxyCommand ssh -q $dbname nc -q0 $thisIP 22");
	$podNames.=$clustername."-".$loop." ";
	for my $i (0..$#hostlines)
	{
		if(@hostlines[$i] =~ m/$clustername-$loop/)
		{
			@hostlines[$i]=$thisIP."  ".$clustername."-".$loop."\n";
			print "found $clustername-$loop in hosts file";
		}
	}
	for my $i (0..$#clusterconfiglines)
	{
		if(@clusterconfiglines[$i] =~ m/$clustername = /)
		{
			@clusterconfiglines[$i]='';
		}
	}
	$loop++;
}
print $podNames."'\n";
$podNames=substr($podNames,0,-1);
print $podNames."'\n";
my $hostsfile = "";
$hostsfile.=$_ foreach @hostlines;
print $hostsfile;
$hostsFile->truncFile($hostsfile);

my $clusterlines = "";
$clusterlines.=$_ foreach @clusterconfiglines;
$clusterlines.="$clustername = $podNames\n";
print $clusterlines;
$clusterconfig->truncFile($clusterlines);



exit;
#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;
use DBD::Pg;
use DateTime;

our $dbHandler;
our %dbconf = %{getDBconnects()};
our @dbfile = ();
our $currentDB = $dbconf{"db"};
our $wantDB = 'evergreen';
our $debug = 0;
our $nonInteractive = 0;
our $egPath = shift || '/home/opensrf/repos/Evergreen';
our $dbControlFile = shift || '/home/opensrf/repos/Evergreen/db_control.txt';
our $egRepoPath = shift || '/home/opensrf/repos/Evergreen-build';
our $egRestartTriggerFile = '/home/opensrf/repos/Evergreen/eg_restart_go';
our @currentDBs = ();

printHelp if($egPath eq 'help');

$egPath   =~ s/\/$//g;
$egRepoPath   =~ s/\/$//g;

$ENV{'PGUSER'}     = $dbconf{"dbuser"};
$ENV{'PGPASSWORD'} = $dbconf{"dbpass"};
$ENV{'PGPORT'}     = $dbconf{"port"};
$ENV{'PGHOST'}     = $dbconf{"dbhost"};
$ENV{'PGDATABASE'} = $dbconf{"db"};;

execSystemCMD('touch ' . $dbControlFile) if(!(-e $dbControlFile));

parseControlFile($dbControlFile);

getCurrentDatabases();

makeControlFileReality();

printOut("Current: [$currentDB]") if $debug;
printOut("Wanted:  [$wantDB]") if $debug;
if($currentDB ne $wantDB) {
    printOut("Switching Evergreen to use database: [$wantDB]");
    populateDBFromCurrentGitBranch($wantDB, 1, 0);
    execSystemCMD("touch '$egRestartTriggerFile'", 1);
}

sub makeControlFileReality {
    my $synced = 0;
    foreach(@dbfile) {
        my %thisDatabase = %{$_};
        my $exists = 0;
        my $looking = $thisDatabase{'dbname'};
        foreach(@currentDBs)
        {
            printOut("database '$looking' exists") if($debug && lc $_ eq lc $looking);
            $exists = 1 if(lc $_ eq lc $looking);
        }
        if(!$exists)
        {
            rsyncEvergreenRepo() if !$synced;
            $synced = 1;
            my $type = '--load-all-sample';
            $type = '--load-concerto-enhanced' if($thisDatabase{'type'} eq 'enhanced');
            printOut("Creating database '" . $thisDatabase{'dbname'} . "' loaded with: '$type'");
            populateDBFromCurrentGitBranch($thisDatabase{'dbname'}, 0, $type);
        }
    }
}

sub parseControlFile {
    my $file = shift;
    my @lines = @{readFile($file)};
    @dbfile = ();
    foreach(@lines) {
        my @splits = split(/[\t\s]+/, $_);
        printOut(Dumper(\@splits)) if $debug;
        # allow the last column to be missing or null
        if( ($#splits == 2) || ($#splits == 1))
        {
            my %newob = (
                'dbname' => lc @splits[0],
                'type' => lc @splits[1],
                'selected' => @splits[2],
            );
            # little sanity checking
            if ($newob{'type'} eq 'standard' || $newob{'type'} eq 'enhanced')
            {
                $wantDB = $newob{'dbname'} if(@splits[2] && @splits[2] eq '*');
                push(@dbfile, \%newob) 
            }
        }
    }
    printOut(Dumper(\@dbfile) )if $debug;
}

sub readFile {
    my $file   = shift;
    my $trys   = 0;
    my $failed = 0;
    my @lines;

    if ( -e $file ) {
        my $worked = open( inputfile, '< ' . $file );
        if ( !$worked ) {
            printOut("******************Failed to read file*************");
        }
        binmode( inputfile, ":utf8" );
        while ( !( open( inputfile, '< ' . $file ) ) && $trys < 100 ) {
            printOut("Trying again attempt $trys");
            $trys++;
            sleep(1);
        }
        if ( $trys < 100 ) {
            @lines = <inputfile>;
            close(inputfile);
        }
        else {
            printOut("Attempted $trys times. COULD NOT READ FILE: $file");
        }
        close(inputfile);
    }
    else {
        printOut("File does not exist: $file");
    }
    return \@lines;
}

sub populateDBFromCurrentGitBranch {
    my $db                 = shift;
    my $doConfig           = shift;
    my $dbLoadSwitch       = shift;
    my $eg_db_config_stock = "Open-ILS/src/support-scripts/eg_db_config.in";
    my $eg_db_config_temp  = "Open-ILS/src/support-scripts/eg_db_config";
    my $eg_config_stock    = "Open-ILS/src/extras/eg_config.in";
    my $eg_config_temp     = "Open-ILS/src/extras/eg_config";
    fix_eg_config( $egRepoPath . "/$eg_db_config_stock", $egRepoPath . "/$eg_db_config_temp" );
    fix_eg_config( $egRepoPath . "/$eg_config_stock",    $egRepoPath . "/$eg_config_temp" );
    my $exec = "cd '$egRepoPath' && perl '$eg_db_config_temp'";
    $exec .= " --create-database --create-schema" if($dbLoadSwitch);
    $exec .= " --user " . $dbconf{"dbuser"};
    $exec .= " --password " . $dbconf{"dbpass"};
    $exec .= " --hostname " . $dbconf{"dbhost"};
    $exec .= " --port " . $dbconf{"port"};
    $exec .= " --database $db";
    $exec .= " --admin-user admin";
    $exec .= " --admin-pass demo123";
    $exec .= " --service all --update-config" if($doConfig);
    $exec .= " $dbLoadSwitch" if($dbLoadSwitch);
    execSystemCMD($exec);
}

sub fix_eg_config {
    my $inFile     = shift;
    my $outputFile = shift;

    unlink $outputFile if -e $outputFile;
    my $outHandle;
    open( $outHandle, '>> ' . $outputFile );
    binmode( $outHandle, ":utf8" );

    my @lines      = @{ readFile($inFile) };
    my %replaceMap = (
        '\@prefix\@'                => '/openils',
        '\@datarootdir\@'           => '${prefix}/share',
        '\@BUILDILSCORE_TRUE\@'     => '',
        '\@BUILDILSWEB_TRUE\@'      => '',
        '\@BUILDILSREPORTER_TRUE\@' => '',
        '\@BUILDILSCLIENT_TRUE\@'   => '',
        '\@PACKAGE_STRING\@'        => '',
        '\@bindir\@'                => '${exec_prefix}/bin',
        '\@libdir\@'                => '${exec_prefix}/lib',
        '\@TMP\@'                   => '/tmp',
        '\@includedir\@'            => '${prefix}/include',
        '\@APXS2\@'                 => '',
        '\@sysconfdir\@'            => '/openils/conf',
        '\@LIBXML2_HEADERS\@'       => '',
        '\@APR_HEADERS\@'           => '',
        '\@APACHE2_HEADERS\@'       => '',
        '\@localstatedir\@'         => '',
        '\@docdir\@'                => '',
    );

    foreach (@lines) {
        my $line = $_;

        # this file has some placeholders. We're not going to make use of
        # this feature in the script, but it won't run unless those are populated
        while ( ( my $key, my $value ) = each(%replaceMap) ) {
            $line =~ s/$key/$value/g;
        }
        print $outHandle $line;
    }
    chmod( 0755, $outHandle );
    close($outHandle);
}

sub rsyncEvergreenRepo {
    # get the current branch so we can switch back
    my $exec = "rsync -a --exclude '.git' --exclude 'node_modules' --no-owner --no-perms --size-only --chown 0:0 $egPath/ $egRepoPath";
    execSystemCMD( $exec, 1 );
    $exec = "cd $egRepoPath/Open-ILS/src/sql/Pg && rm 000.english.pg1* 000.english.pg95.fts-config.sql 000.english.pg96.fts-config.sql";
    execSystemCMD( $exec, 1 );
    $exec = "cd $egRepoPath/Open-ILS/src/sql/Pg && cp 000.english.pg94.fts-config.sql 000.english.pg10.fts-config.sql && cp 000.english.pg94.fts-config.sql 000.english.pg11.fts-config.sql && cp 000.english.pg94.fts-config.sql 000.english.pg12.fts-config.sql && cp 000.english.pg94.fts-config.sql 000.english.pg13.fts-config.sql && cp 000.english.pg94.fts-config.sql 000.english.pg14.fts-config.sql && cp 000.english.pg94.fts-config.sql 000.english.pg95.fts-config.sql && cp 000.english.pg94.fts-config.sql 000.english.pg96.fts-config.sql";
    execSystemCMD( $exec, 1 );
}

sub execSystemCMD {
    my $cmd          = shift;
    my $ignoreErrors = shift;
    printOut("executing $cmd") if $debug;
    system($cmd) == 0;
    if ( !$ignoreErrors && ( $? == -1 ) ) {
        die "system '$cmd' failed: $?";
    }
    printOut("Done executing $cmd") if $debug;
}

sub execSystemCMDWithReturn {
    my $cmd       = shift;
    my $dont_trim = shift;
    my $ret;
    printOut("executing $cmd") if $debug;
    open( DATA, $cmd . '|' );
    my $read;
    while ( $read = <DATA> ) {
        $ret .= $read;
    }
    close(DATA);
    return 0 unless $ret;
    $ret = substr( $ret, 0, -1 ) unless $dont_trim;    #remove the last character of output.
    printOut("Done executing $cmd") if $debug;
    return $ret;
}

sub getCurrentDatabases {
    @currentDBs = ();
    my $cmd = "psql -c '\\l'";
    my $answer = execSystemCMDWithReturn($cmd);
    my @lines = split(/\n/, $answer);
    # first three lines are headers
    shift @lines;
    shift @lines;
    shift @lines;
    # last row is summary
    pop @lines;
    foreach(@lines)
    {
        my @cols = split(/\|/, $_);
        # first column is the database name
        my $database = shift @cols;
        $database =~ s/[\s|\t]//g;
        push(@currentDBs, $database)
            if($database ne 'template0' && $database ne 'template1' && $database ne '' && $database ne 'postgres');
    }
}

sub printOut {
    my $line = shift;
    my $dt   = DateTime->now(time_zone => "local");
    my $date = $dt->ymd;
    my $time = $dt->hms;
    my $datetime = makeEvenWidth($dt->ymd . " ". $dt->hms, 20);
    print $datetime .": $line\n";
}

sub makeEvenWidth {
    my $ret;

    if($#_ != 1)
    {
        return;
    }
    $line = shift;
    $width = shift;
    $ret=$line;
    if(length($line)>=$width)
    {
        $ret=substr($ret,0,$width);
    }
    else
    {
        while(length($ret)<$width)
        {
            $ret=$ret." ";
        }
    }
    return $ret;
}

sub getDBconnects
{
    my $openilsfile = shift || '/openils/conf/opensrf.xml';
    my $xml = new XML::Simple;
    my $data = $xml->XMLin($openilsfile);
    my %conf;
    $conf{"dbhost"}=$data->{default}->{apps}->{"open-ils.storage"}->{app_settings}->{databases}->{database}->{host};
    $conf{"db"}=$data->{default}->{apps}->{"open-ils.storage"}->{app_settings}->{databases}->{database}->{db};
    $conf{"dbuser"}=$data->{default}->{apps}->{"open-ils.storage"}->{app_settings}->{databases}->{database}->{user};
    $conf{"dbpass"}=$data->{default}->{apps}->{"open-ils.storage"}->{app_settings}->{databases}->{database}->{pw};
    $conf{"port"}=$data->{default}->{apps}->{"open-ils.storage"}->{app_settings}->{databases}->{database}->{port};
    return \%conf;

}

sub printHelp {
    print "Usage: ./db_switcher.pl /path/to/Evergreen_git_repo /path/to/db_control_file

This program automates the process of hot swapping a running Evergreen machine from
one database to another. It will also create the database from the requested branch
if the database doesn't exist.

The db_control_file is a simple text file. Each line in the file represents a database
We expect a tab or space delimited file that looks like this:
db_name\t[standard/enhanced]\t* (astricks symbol to indicate the current/wanted database)

";
    exit 0;
}

#!/usr/bin/perl
#This script allows one to start a secondary program and let it run for a period of time. 
#If the program doesnt complete in a specified amount of time, 
#the script can either kill the program and/or simply start another one after the interval has passed.

use POSIX ":sys_wait_h";
sub killPid
{
    $pid = shift || return 0;
    if(check_process($pid))
    {
        print "num killed = " . kill (9, $pid) . "\n";
    }
    else
    {
        print STDERR "didnt find $pid\n";
    }
}

sub check_process
{
    my $proc_name = shift || return 0;
    $running = `ps -A`;
    if( $running =~ /^{$proc_name}\s/)
    {
        return 1;
    }
    return 0;
}

my $child_pid = 0;
sub handleInt
{
    killPid($child_pid);
    exit(0);
}

sub main
{
    $SIG{INT}=\&handleInt;
    my $arg = shift @ARGV || die "have to provide an executable to run\n";
    my $sleep_time = shift @ARGV || 60;
    my $killAfterTime = shift @ARGV || 1;
    my $numTimesToRun = shift @ARGV || 0;

    my $counter = 0;
    while(($numTimesToRun > 0 && $counter++ < $numTimesToRun) || !$numTimesToRun)
    {
        $child_pid = fork();
        if(!$child_pid)
        {
            print STDERR "running $arg at " . localtime(time) . "\n";
            exec($arg);
        }

        sleep $sleep_time;

        my $matchedKid = 0;
        my $kidWhoDied = -1;
        do
        {
            my $kidWhoDied = waitpid(-1, WNOHANG);
            $matchedKid = 1 if($kidWhoDied == $child_pid);
        }while($kidWhoDied > 0);
        killPid($child_pid) if(!$matchedKid && $killAfterTime)
    }
}
main();

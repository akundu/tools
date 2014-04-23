#!/home/y/bin/perl
use POSIX ":sys_wait_h";
use strict;

my $host = shift || die "Usage: <host:port to connect to> [num_procs|4] [num_clients_per_process|1000] [num_requests_per_process|1000000] [different_urls_per_process|0] \n";
my $num_to_fork = shift || 4;
my $num_clients_per_process = shift || 1000;
my $num_requests_per_process = shift || 1000000;
my $change = shift || 0;

sub main
{
    my $pid = $$;

    my $num_to_put_out = 1;
    my $fork_cnt = 0;
    while($fork_cnt++ < $num_to_fork)
    {
        $num_to_put_out = $fork_cnt if($change);

        my $c_pid = fork();
        if($c_pid == 0)
        {
            #my $command = "ab -c $num_clients_per_process -n $num_requests_per_process -k 'http://$host/$num_to_put_out.html' 2>/dev/null |grep -E \"requests|Requests per second|Time per request|9.*%\"|tee /tmp/run_ab.$pid.$fork_cnt";
            my $command = "ab -c $num_clients_per_process -n $num_requests_per_process  -k 'http://$host/$num_to_put_out.html' 2>/dev/null |grep -E \"requests|Requests per second|Time per request|9.*%\" > /tmp/run_ab.$pid.$fork_cnt";
            print STDERR "running $command\n";
            my $rc = system("$command");
            exit($rc);
        }
    }

    #wait for the children to ie
    while($fork_cnt--)
    {
        wait();
    }

    #calculate the total thruput
    my $sum = 0;
    open(INPUT, "grep \"Requests per second\" /tmp/run_ab.$pid.*|awk '{print \$4}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
    }
    close(INPUT);
    print "Total req_per_sec = $sum\n";

    #calculate the time per request
    $sum = 0;
    my $num_run = 0;
    open(INPUT, "grep \"(mean)\" /tmp/run_ab.$pid.* |grep \"Time per request\" |awk '{print \$4}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
        $num_run++;
    }
    close(INPUT);
    print "Avg time per request " . int($sum/$num_run) . "\n";

    #calculate the 95th percentile
    $sum = 0;
    $num_run = 0;
    open(INPUT, "grep 95\% /tmp/run_ab.$pid.* |awk '{print \$3}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
        $num_run++;
    }
    close(INPUT);
    print "95th percentile = " . int($sum/$num_run) . "\n";

    #calculate the 99th percentile
    $sum = 0;
    $num_run = 0;
    open(INPUT, "grep 99\% /tmp/run_ab.$pid.* |awk '{print \$3}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
        $num_run++;
    }
    close(INPUT);
    print "99th percentile = " . int($sum/$num_run) . "\n";

    #completed requests Complete requests:      200000
    $sum = 0;
    open(INPUT, "grep \"Complete requests\" /tmp/run_ab.$pid.*|awk '{print \$3}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
    }
    close(INPUT);
    print "Total completed requests = $sum\n";

    #failed requests Failed requests:        0
    $sum = 0;
    open(INPUT, "grep \"Failed requests\" /tmp/run_ab.$pid.*|awk '{print \$3}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
    }
    close(INPUT);
    print "Total failed requests = $sum\n";
    if($sum)
    {
        open(INPUT, "grep -i fail /tmp/run_ab.$pid.*|");
        while(<INPUT>)
        {
             print "failure = $_";
        }
        close(INPUT);
    }
    
    
    #keep alive requests Keep-Alive requests:    200001
    $sum = 0;
    open(INPUT, "grep Keep-Alive /tmp/run_ab.$pid.*|awk '{print \$3}'|");
    while(<INPUT>)
    {
        chomp;
        $sum += $_;
    }
    close(INPUT);
    print "Total keep alive requests = $sum\n";
    
    #remove the extraneous files
    system("rm /tmp/run_ab.$pid*");
}

main();

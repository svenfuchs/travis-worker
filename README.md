Experimental rewrite of our good ol', crufty `travis-worker`, focussing
on Docker, simplicity and extensibility for now.


#### Current state

* Can accept jobs and commands (`cancel_job`) via AMQP, but receivers are
  pretty modular so other receivers can be added (e.g. pulling jobs via HTTP
  while keeping commands on AMQP).

* Simply runs `docker run [cmd]` via `java.lang.UNIXProcess` and reads
  `stdout/stderr`.

  * It can therefor optionally wrap the docker command into an `ssh` shell
    command transparently, and execute the jobs on arbitrary hosts.

  * This pushes a lot of complexity out to (probably very) battletested tools
    like `ssh` and `java.lang.UNIXProcess`, and keeps our own code fairly simple.

  * It also allows to specify multiple Docker "hosts" in the configuration, each
    of which will run a particular, fixed number of VMs (containers).

* Can run receivers for multiple queues, each tied to an array of "hosts"
  where it shells out to in order to run a Docker container, either locally or
  via ssh (of course there could be other adapters).

* Can use any number of pluggable reporter adapters (e.g. AMQP alongside
  with a logger, or memory for testing), but at this point they'll all just
  report whatever they receive from the runner.

  I haven't thought about more sophisticated routing (e.g. routing log traffic
  to a different queue or even protocol based on a flag in the job payload for
  experimental reasons), but since there's a central dispatch point I guess it
  should be trivial to add.

* All limits wrap around the main execution thread and simply raise so it
  should be fairly easy to add/modify limits.

* Cleans up stopped Docker containers in a separate `cleanup` thread async.

* Stops gracefully on `SIG_TERM` and ungracefully on `SIG_INT` (`ctrl-c`).


#### Limitations

* Uses the same basic design for acquiring VMs as the old worker did. I.e.,
  the number of available VMs is hardcoded in the config file. The worker
  will simply assume they're available locally and/or a flexible number of
  remote hosts.

  It would be cool to be able to dynamically scale up "docker hosts" (e.g. via
  EC2 or DigitalOcean API), and have more receivers connect as soon as these are
  available and pick up work. But maybe that's more related to the recurring
  "centralized configuration service" topic that we also have.


#### Not ported/implemented

* bb and sauce vms
* decode repo key
* metrics


#### Scenarios

Successful build:

    [worker-1][job-1][part-101] log: .
    [worker-1][job-1] job:test:finish: {:id=>1, :state=>"passed", :finished_at=>"2014-01-17 21:50:52 UTC"}
    [worker-1][job-1][part-103] log: [final]

When the global timeout is exceeded:

    [worker-1][job-1][part-10] log: Error: Execution expired after 0 minutes.
    [worker-1][job-1][part-10] log: This build has been terminated.
    [worker-1][job-1] job:test:finish: {:id=>1, :state=>"errored", :finished_at=>...}
    [worker-1][job-1][part-11] log: [final]

When the log silence timeout is exceeded:

    [worker-1][job-1][part-1] log: Error: No output has been received in the last 0 minutes.
    [worker-1][job-1][part-1] log: This build has been terminated.
    [worker-1][job-1][part-2] log: [final]
    [worker-1][job-1] job:test:finish: {:id=>1, :state=>"errored", :finished_at=>...}
    [worker-1][job-1][part-3] log: [final]

When the log limit is exceeded:

    [worker-1][job-1][part-7] log: Error: The log length has exceeded the limit of 0 MB.
    [worker-1][job-1][part-7] log: Hint: this often means the same exception was raised over and over.
    [worker-1][job-1][part-8] log: This build has been terminated.
    [worker-1][job-1] job:test:finish: {:id=>1, :state=>"errored", :finished_at=>...}
    [worker-1][job-1][part-9] log: [final]

When the ssh remote host is not reachable:

    [worker-1][job-1][part-0] log: Error: ssh: connect to host localhost port 22: Connection refused
    [worker-1][job-1][part-1] log: This build will be restarted.
    [worker-1][job-1] job:test:reset: {:id=>1, :state=>"reset", :finished_at=>...}
    [worker-1][job-1][part-2] log: [final]

When Docker is down:

    [worker-1][job-1][part-1] log: Error: Can't connect to docker daemon. Is 'docker -d' running on this host?
    [worker-1][job-1][part-2] log: This build will be restarted.
    [worker-1][job-1] job:test:reset: {:id=>1, :state=>"reset", :finished_at=>...}
    [worker-1][job-1][part-3] log: [final]

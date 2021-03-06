This is a multi-machine vagrant configuration that 
models two rundeck instances sharing a mysql database.

## Vagrant configuration.

The vagrant configuration defines the following virtual machines:

* **mysql**: Common database instance shared by both rundeck hosts.
* **rundeck1**: The user-facing "primary" rundeck.
* **rundeck2**: The standby rundeck instance. It runs jobs 
  to sync from the _primary_ and check it to see if the secondary should "takeover".

All machines use the same centos base box and install software via yum/rpm.


## Requirements

* Internet access to download packages from public repositories.
* [Vagrant 1.2.2](http://downloads.vagrantup.com)

## Startup

Start up the VMs in the following order.

    vagrant up mysql
    vagrant up rundeck1
    vagrant up rundeck2

You can access the rundecks from your host machine through vagrant's port forwarding.

* rundeck1: http://192.168.50.4:4440
* rundeck2: http://192.168.50.5:4440

Login to either rundeck instance using user/pass: admin/admin

### Shell Logins

You can login into any VM via vagrant ssh. Eg: login to the secondary rundeck:

    vagrant ssh rundeck2
    
Once logged in as vagrant, you can use sudo/su to change users.    
Here's how to change user to the rundeck login:

    sudo su - rundeck

You can also ssh to the rundeck VMs using user/password: rundeck/rundeck

## Operations

The jobs used for synchronization and takeover are in a job group
called "failover". The jobs are pre-configured by the provisioning process
and have default option values appropriate for this environment.

* failover/Check-Or-Takeover: Runs the check job and if it fails, the "takeover" job executes.
* failover/Sync: Synchronize the job state data from the primary.
* failover/check: Test if the primary responds to an API call. 
* failover/takeover: Turn off the schedule for the failover jobs and update secondary's tags. 

Go to the secondary rundeck and navigate to the "failover/check" job and run it.
You should see system info about the primary displayed in the job output.

    05:35:59    # System Stats for Rundeck 2.0.0 on node rundeck1
	05:35:59	- up since: 2014-01-29T15:12:06Z
	05:35:59	- cpu avg: 0.0
	05:35:59	- mem free: 124876264

Next, try the "failover/Sync" job. This job uses rsync to copy job output logs from the primary
so they can be viewable on the secondary.

## Takeover Scripts

The failover/takeover jobs is responsible for executing any procedure
needed to transition the secondary server to become the primary server.

The takeover job defines three steps that each call a separate script:

* update-jobs.sh: Removes the cron schedule for the Check-Or-Takeover and Sync jobs. 
* update-resources.sh: Updates the resource data to show the secondary is now tagged primary.
* do-switch.sh: This is a place holder script which might update load balancer or EIPs.


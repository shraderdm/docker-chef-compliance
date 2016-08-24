Chef Compliance
===============

This is for the biggest part a fork/copy of the great [3ofcoind docker-chef-server](https://github.com/3ofcoins/docker-chef-server). So most kudos goes to them.
This image runs [Chef Compliance](https://downloads.chef.io/compliance).

Git repository containing the Dockerfile lives at
https://github.com/bytesource-net/docker-chef-compliance/

Ports
-----

Ports 80 (HTTP) and 443 (HTTPS) are exposed.

Hostname
--------

Chef Compliance is using the systems hostname so upon creating the container the hostname should be set to the FQDN used for accessing the Webinterface.

Volumes
-------

`/var/opt/chef-compliance` directory, that holds all Chef server data, is a
volume. Directories `/var/log/chef-compliance` and `/etc/chef-compliance` are linked
there as, respectively, `log` and `etc`.

If there is a file `etc/chef-compliance-local.rb` in this volume, it will
be read at the end of `chef-compliance.rb` and it can be used to customize
Chef Server's settings.

Signals
-------

 - `docker kill -s HUP $CONTAINER_ID` will run `chef-compliance-ctl reconfigure`
 - `docker kill -s USR1 $CONTAINER_ID` will run `chef-compliance-ctl status`

Usage
-----

### Prerequisites and first start

The `kernel.shmmax` and `kernel.shmall` sysctl values should be set to
a high value on the host. You may also run Chef server as a privileged
container to let it autoconfigure -- but the setting will propagate to
host anyway, and it would be the only reason for making the container
privileged, so it is better to avoid it.

First start will automatically run `chef-compliance-ctl
reconfigure`. Subsequent starts will not run `reconfigure`, unless
file `/var/opt/chef-compliance/bootstrapped` has been deleted. You can run
`reconfigure` (e.g. after editing `etc/chef-compliance.rb`) using
`docker exec` or by sending SIGHUP to the container: `docker kill
-HUP $CONTAINER_ID`.

### Maintenance commands

Chef Compliance's design makes it impossible to wrap it cleanly in
a container - it will always be necessary to run custom
commands. While some of the management commands may work with linked
containers with varying amount of ugly hacks, it is simpler to have
one way of interacting with the software that is closest to
interacting with a Compliance Server installed directly on host (and thus
closest to supported usage).

This means you need Docker 1.3+ with `docker exec` feature, and run
`chef-compliance-ctl` commands like:

    docker exec $CONTAINER_ID chef-compliance-ctl status
    docker exec $CONTAINER_ID chef-compliance-ctl tail …
    docker exec $CONTAINER_ID chef-compliance-ctl …

### Publishing the endpoint

This container is not supposed to listen on a publically available
port. It is very strongly recommended to use a proxy server, such as
[nginx](http://nginx.org/), as a public endpoint.

A sample nginx configuration looks like this:

    server {
      listen 443 ssl;
      server_name compliance.example.com;
      ssl_certificate /path/to/compliance.example.com.pem;
      ssl_certificate_key /path/to/compliance.example.com.key;
      client_max_body_size 4G;
      location / {
          proxy_pass http://127.0.0.1:5000;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto https;
          proxy_redirect default;
          proxy_redirect http://compliance.example.com https://compliance.example.com;
      }
    }

### Backup and restore

Currently compliance has not official backup instructions.

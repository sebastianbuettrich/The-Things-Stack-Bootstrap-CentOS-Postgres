# The-Things-Stack-Bootstrap-CentOS-Postgres
Script to bootstrap The Things Stack v3, with docker on CentOS, using postgreSQL

This is based on Hylke Visser's bootstrap script,
https://gist.github.com/htdvisser/4503f30699308a7fd9e0aa3ebc2f3eb4
(thanks!), 
and thus based on the Getting Started Guide, https://thethingsstack.io/getting-started/

with the only changes being:

  * prepare.sh adapted to CentOS 7 instead of Ubuntu 18
  * using postgreSQL instead of cockroach SQL
 
 Else all instructions are equally valid, as given in link above:
 
 ## Preparation

- Clone this.
- Spin up a fresh CentOS7 server.
  - Var `SSHUser`: the username that will be used to SSH into the server. This user must be able to `sudo`.
- Point a public DNS record to your server's IP address. It may take some time before this resolves.
  - Var `Host`: the DNS record.
- Try to remember your email address.
  - Var `AdminEmail`: your email address.

## Usage

```bash
$ SSHUser=<username> Host=thethings.example.com AdminEmail=you@example.com ./bootstrap.sh
```

## Next Steps

- This script does not configure all options. Read the documentation to learn more about the available options.
- This script is not intended for production servers. You don't want to use the `latest` tag of the Docker images. You don't want a single instance of postgreSQL. You don't want a single instance of Redis. You don't want to store your blobs on a local disk.

## Support

No support on this script; help yourself.


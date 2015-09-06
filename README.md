# xip Release

xip is a [BOSH release](https://bosh.io/docs/create-release.html)
of the [PowerDNS](https://www.powerdns.com/) nameserver combined with an enhanced [xip.io](http://xip.io/) [*Pipe*](https://doc.powerdns.com/md/authoritative/backend-pipe/) backend.

Deploying this release will create a DNS nameserver that will reply to xip.io-style queries, e.g. a query for the [A record](https://support.dnsimple.com/articles/a-record/) of the hostname "192.168.0.1.xip.io" will return the IP address "192.168.0.1". The domain can be customized (it does not need to be *xip.io*)

The enhanced xip.io *Pipe* backend allows the lookup of hostnames with dashes as separators (not solely dots), for example, "172-16-100-1.xip.io" resolves to 172.16.100.1.

## xip BOSH Manifest

### 1. Job Properties

xip's BOSH Properties are
scoped under the `xip` element. A typical BOSH manifest has the following
layout:

```yaml
jobs:
- name: xip
  properties:
    xip:
      xip_pdns_conf: |
        ...
      named_conf: |
        ...
      pdns_conf: |
        ...
```

xip has the following job properties:

* `xip_pdns_conf`: *Required*.  This is the configuration for the xip.io backend. It is a bash script that sets the environment variables that configure the behavior (e.g. the domain name). In the following example, we configure the domain name to be "sslip.io":

  ```bash
  XIP_TIMESTAMP="2015081600"
  XIP_DOMAIN="sslip.io"
  XIP_ROOT_ADDRESSES=( "52.0.56.137" )
  XIP_NS_ADDRESSES=( "52.0.56.137" "78.47.249.19" )
  XIP_TTL=300
  ```

* `pdns_conf`: *Optional*. Defaults to:

  ```
  launch=pipe
  pipe-command=/var/vcap/jobs/xip/bin/xip-pdns /var/vcap/jobs/xip/etc/xip-pdns.conf
  ```

  To use PowerDNS's *BIND* backend, include and configure it here, for example,

  ```
  launch=bind:first,pipe:second
  slave=yes
  bind-first-config=/var/vcap/jobs/xip/etc/named.conf
  pipe-second-command=/var/vcap/jobs/xip/bin/xip-pdns /var/vcap/jobs/xip/etc/xip-pdns.conf
  ```

* `named_conf`: *Optional*. Defaults to empty string. If using PowerDNS's *BIND* backend, populate this property. For example, to configure a slave nameserver for the domain *nono.com*,

  ```
  zone "nono.com" {
    type slave;
    file "/var/vcap/jobs/xip/etc/nono.com";
    masters { 24.23.190.188; };
  };
  ```

### 2. Upload Release to BOSH

If using BOSH (not *bosh-init*), upload the release to the BOSH director:

```
bosh upload release https://s3.amazonaws.com/xip-release/xip-1.tgz
```

If using *bosh-init*, the BOSH manifest must contain the URL and SHA of the release, for example:

```
releases:
- name: xip
  url:  https://s3.amazonaws.com/xip-release/xip-1.tgz
  sha1: b544389803a6ef21b6dd05a5c13526dab0df7ac3
```

## <a name="deploy"></a>Deploying a Custom Version of xip to Amazon AWS

In this example, we deploy custom version of xip.io to a t2.micro instance on Amazon AWS:

### 1. Create the Amazon AWS infrastructure

The BOSH documentation has an excellent [walk-through](http://bosh.io/docs/init-aws.html#prepare-aws) that describes how to create the proper infrastructure. After we have finished the walk-through, we have the following items which we will use to populate our BOSH manifest:

* Elastic IP: **52.0.76.229**
* Subnet: **subnet-1c90ef6b**
* Private Key: **/Users/cunnie/.ssh/aws_nono.pem**
* Access Key: **AKIAxxxxxxxxxxxxx**
* Access Key Secret: **0+B1Xxxxxxxxxxxxxxxxxxxxxxxxxx**
* AWS Key Pair name: **aws_nono**
* Security Group: **no-filter-vpc**

### 2. Customize xip's Configuration

In addition to the infrastructure items above, we also need to customize our xip-specific information, which we will use in the `jobs.properties.xip.xip_pdns_conf` section of our BOSH manifest:

* a current timestamp: **2015090512**
* our domain name: **sslip.io**
* our domain's nameservers (as verified by `nslookup -query=ns sslip.io`): **52.0.56.137** and **78.47.249.19**
* our domain's webserver's IP address (for http://slip.io): **52.0.56.137**

### 3. Construct the BOSH Manifest

We construct a manifest using the information gathered in the previous steps. Our manifest looks like [this](https://github.com/cloudfoundry-community/xip-release/blob/master/examples/xip-bosh-init-aws.yml). *(Hint: search for all occurrences of 'CHANGEME' within the manifest and update appropriately)*

### 4. Deploy

We deploy our manifest using [bosh-init](https://github.com/cloudfoundry/bosh-init)

```
bosh-init deploy examples/xip-bosh-init-aws.yml
```

### 5. Test

We test our newly-deployed nameserver to make sure it's functioning properly:

```bash
export NAMESERVER_IP=52.0.76.229
dig +short @$NAMESERVER_IP 127.0.0.1.sslip.io
# 127.0.0.1
dig +short @$NAMESERVER_IP 192-168-0-1.sslip.io
# 192.168.0.1
dig +short @$NAMESERVER_IP google.com
# '', no answer, does not perform recursive queries
```

### 6. Update Domain's Registrar's Nameserver Records

Now that we're satisfied that our newly-deployed nameserver is functioning properly, we log into our registrar and update our domain's (sslip.io's) nameserver records to include our new nameserver.

Note that we need to repeat this process at least one more time in order to have two nameservers (minimum requirement for a domain), and we must not forget to retire our old nameservers.

## BUGS

* The BOSH packaging script uses `apt-get` and `yum` to install dependencies (boost). This is considered undesirable, for good reason. It's also wonderfully convenient.
* PowerDNS is not built with database backends, only the *Pipe*, [*Remote*](https://doc.powerdns.com/md/authoritative/backend-remote/), and [*BIND*](https://doc.powerdns.com/md/authoritative/backend-bind/)  backends.
* This release has only been tested on a CentOS stemcell (not Ubuntu),only deployed with *bosh-init* (not with a BOSH director), only deployed to Amazon AWS (not vSphere or OpenStack).

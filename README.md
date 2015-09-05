# XIP Release

XIP is a [BOSH release](https://bosh.io/docs/create-release.html)
of the [PowerDNS](https://www.powerdns.com/) nameserver combined with a modified [xip.io](http://xip.io/) *pipe* backend.

Deploying this release will create a DNS nameserver that will reply to xip.io-style queries, e.g. a query for the [A record](https://support.dnsimple.com/articles/a-record/) of the hostname "192.168.0.1.xip.io" will return the IP address "192.168.0.1". The domain can be customized (it does not need to be *xip.io*)

The modified xip.io *pipe* back end allows the lookup of hostnames with dashes as separators (not solely dots), for example, "172-16-100-1.xip.io" resolves to 172.16.100.1.

## XIP BOSH Manifest

### 1. Job Properties

XIP's BOSH Properties are
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

XIP has the following job properties:

* `xip_pdns_conf`: *Required*.  This is the configuration for the xip.io back end. It is a bash script that sets the environment variables that configure the behavior of the xip.io back end (e.g. the domain name). In the following example, we configure the domain name to be "sslip.io":
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
  To use PowerDNS's *named* back end, include and configure it here, for example,
  ```
  launch=bind:first,pipe:second
  slave=yes
  bind-first-config=/var/vcap/jobs/xip/etc/named.conf
  pipe-second-command=/var/vcap/jobs/xip/bin/xip-pdns /var/vcap/jobs/xip/etc/xip-pdns.conf
  ```
* `named_conf`: *Optional*. Defaults to empty string. If using PowerDNS's *named* back end, populate this property. For example, to configure a slave nameserver for the domain *nono.com*,
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

## Deploying a Custom Version of xip.io

In this example, we deploy custom version of xip.io to 2 &times; t2.micro instances
on Amazon AWS:

* our domain name is *sslip.io*
* our [elastic IPs]() are

* clone this repo:
  ```bash
  git clone https://github.com/cloudfoundry-community/xip-release
  ```
*

## BUGS

* The BOSH packaging script uses `apt-get` and `yum` to install dependencies (boost). This is considered undesirable, for good reason. It's also wonderfully convenient.
* PowerDNS is not built with database backends, only the *pipe*, *remote*, and *bind*  backends.
* This release has only been tested on a CentOS stemcell (not Ubuntu),only deployed with *bosh-init* (not with a BOSH director), only deployed to Amazon AWS (not vSphere or OpenStack).

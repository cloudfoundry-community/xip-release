# XIP Release

XIP is a [BOSH release](https://bosh.io/docs/create-release.html)
of the [PowerDNS](https://www.powerdns.com/) nameserver combined with
a modified [xip.io](http://xip.io/) *pipe* backend.

## XIP BOSH Manifest

### 1. Job Properties

XIP's BOSH Properties are
scoped under the `xip` element. A typical BOSH manifest would have the following
layout:

```
jobs:
- name: xip
  properties:
    xip:
      xip_pdns_conf: |
        ...
      named_conf: |
        ...
```
* `xip_pdns_conf`: *Required*. Defaults to
* `pdns_conf`: *Optional*. Defaults to:
   ```
   launch=pipe
   pipe-command=/var/vcap/jobs/xip/bin/xip-pdns /var/vcap/jobs/xip/etc/xip-pdns.conf
   ```
* `named_conf`: *Optional*. Defaults to empty string.

### 2. Release information

The BOSH manifest must contain the URL and SHA of the release. For example (this
is a valid working release):

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

* The BOSH packaging script uses `apt-get` and `yum` to install dependencies (boost).
This is considered undesirable, for good reason. It's also wonderfully convenient.
* PowerDNS is not built with database backends, only the *pipe*, *remote*, and *bind*  backends.

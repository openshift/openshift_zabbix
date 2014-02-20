OpenShift-Zabbix
================

* [Summary](#summary)
* [Scope](#scope)
* [License](#license)
* [File Layout](#file-layout)
* [Prerequisites](#prerequisites)
* [Getting Started](#getting-started)

Summary
=======

This repository contains monitoring scripts and configuration files to enable
monitoring an OpenShift installation with [Zabbix](http://www.zabbix.com/).
Many of these scripts originated with the [OpenShift
Online](https://www.openshift.com/products/online) product, but are expected to be useful in
monitoring an [OpenShift
Enterprise](https://www.openshift.com/products/enterprise) installation as well.

Scope
=======

While Zabbix is the primary target for these scripts, it is not expected to be
the only use case. Many of these scripts should be capable of being utilized with
any Netowrk Monitoring Software with little or no modifications. Where changes
are required to support other monitoring solutions, patches are welcome.

This repository also contains configuration management code for deploying and
configuring the scripts using Puppet. Similarly, while Puppet is the primary
target, patches to support other configuration management software is welcome.

License
=======

All code in this repository is licensed under the Apache License, Version 2.0.
See the LICENSE file for the complete license text.

Copyrights are attributed individually in each file. If no attribution exists,
the file is Copyright 2012 Red Hat Inc.

File Layout
===========

    ./openshift_zabbix/
    |-- files/           - Static files
    |   |-- checks/      - Monitoring check scripts
    |   |-- lib/         - Libraries used by checks
    |   |-- userparams/  - Zabbix userparameter configuration files
    |   `-- xml/         - XML template files defining Zabbix Templates.
    |-- manifests/       - Puppet configuration manifests
    `-- templates/       - ERB Templated files
        |-- checks/      - ERB Templated monitoring check scripts
        |-- lib/         - ERB Templated Libraries used by checks
        `-- userparams/  - ERB Templated Zabbix userparameter configuration files

Prerequisites
=============

* Zabbix server
* OpenShift Origin/Enterprise installation
* Puppet server (optional)
    * [puppetlabs-stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib)
* [Zbxapi](https://rubygems.org/gems/zbxapi)

Getting Started
===============

1. Import the XML templates from *openshift_zabbix/files/xml/* directory into
   your Zabbix server.
1. (Optional) Add the openshift\_zabbix module into your Puppet code repository,
   and integrate it into your manifests.
1. Deploy *openshift_zabbix/files/{checks,lib}* onto your OpenShift broker,
   node, and messaging (ActiveMQ) server as documented in
   *openshift_zabbix/manifests*.
1. (Optional) Use *openshift_zabbix/files/openshift_zabbix.conf.sample* as an
   example of how to deploy common configuration settings to your OpenShift
   systems. All openshift\_zabbix check scripts accept either command-line
   arguments or a YAML configuration file.
   (default: /etc/openshift/openshift\_zabbix.conf)

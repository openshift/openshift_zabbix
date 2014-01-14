OpenShift-Zabbix
================

[Summary](#summary)
[Scope](#scope)
[License](#license)
[File Layout](#file%20layout)


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
    |   `-- userparams/  - Zabbix userparameter configuration files
    |-- manifests/       - Puppet configuration manifests
    `-- templates/       - ERB Templated files
        |-- checks/      - ERB Templated monitoring check scripts
        |-- lib/         - ERB Templated Libraries used by checks
        `-- userparams/  - ERB Templated Zabbix userparameter configuration files


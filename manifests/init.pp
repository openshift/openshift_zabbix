# == Class: ::openshift_zabbix
#
# Set up basic zabbix requirements for monitoring an Openshift deployment.
#
# === Parameters
#
# None
#
# === Examples
#
#  include ::openshift_zabbix
#
# === Copyright
#
# Copyright 2012 Red Hat, Inc., All rights reserved.
#
class openshift_zabbix {
    ensure_packages([
        # Provides /usr/bin/oo-ruby, which is required by all check scripts.
        # This is primarily needed on RHEL6, where ruby 1.9.3+ is only
        # available via SCL.
        'openshift-origin-util-scl',

        # Ruby interface into the Zabbix API.
        'rubygem-zbxapi'
    ])
}

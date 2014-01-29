# == Class: ::openshift_zabbix::libs
#
# Distributes libraries used by OpenShift monitoring scripts
#
# === Parameters
#
# None
#
# === Examples
#
#  include ::openshift_zabbix::libs
#
# === Copyright
#
# Copyright 2012 Red Hat, Inc., All rights reserved.
#
class openshift_zabbix::libs {
    $script_dir = '/usr/share/zabbix'

    file { "#{$script_dir}/lib":
        ensure       => directory,
        source       => 'puppet:///modules/openshift_zabbix/lib',
        recurse      => true,
        recurselimit => 2;
    }
}

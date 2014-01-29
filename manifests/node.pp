# == Class: ::openshift_zabbix::node
#
# Configures monitoring scripts for an OpenShift Node
#
# === Parameters
#
# None
#
# === Examples
#
#  include ::openshift_zabbix::node
#
# === Copyright
#
# Copyright 2012 Red Hat, Inc., All rights reserved.
#
class openshift_zabbix::node {
    include ::openshift_zabbix::libs

    $script_dir = '/usr/share/zabbix'

    file { "${script_dir}/check-accept-node":
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/openshift_zabbix/checks/check-accept-node'
    }

    cron { 'check-accept-node':
        ensure  => 'present',
        command => "/usr/local/bin/rand_sleep 900 ${script_dir}/check-accept-node",
        minute  => 0,
        hour    => [ 2,14 ],
        require => File["${script_dir}/check-accept-node"];
    }
}


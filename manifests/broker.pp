# == Class: ::openshift_zabbix::broker
#
# Configures monitoring scripts for an OpenShift Broker
#
# === Parameters
#
# None
#
# === Examples
#
#  include ::openshift_zabbix::broker
#
# === Copyright
#
# Copyright 2012 Red Hat, Inc., All rights reserved.
#
class openshift_zabbix::broker {
    include ::openshift_zabbix::libs

    $script_dir = '/usr/share/zabbix'

    file {
        "${script_dir}/check-mc-ping":
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/openshift_zabbix/checks/check-mc-ping',
            require => Class['::openshift_zabbix::libs'];

        "${script_dir}/check-district-capacity":
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/openshift_zabbix/checks/check-district-capacity',
            require => Class['::openshift_zabbix::libs'];

        "${script_dir}/check-user-action-log":
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/openshift_zabbix/checks/check-user-action-log',
            require => Class['::openshift_zabbix::libs'];
    }

    cron {
        'check-mc-ping':
            ensure  => present,
            command => "${script_dir}/check-mc-ping'",
            minute  => '*/5',
            require => File["${script_dir}/check-mc-ping"];

        'check-district-capacity':
            ensure  => present,
            command => "${script_dir}/check-district-capacity'",
            minute  => '2',
            require => File["${script_dir}/check-district-capacity"];

        'check-user-action-log':
            ensure  => present,
            command => "${script_dir}/check-user-action-log'",
            minute  => '*/5',
            require => File["${script_dir}/check-user-action-log"];
    }
}

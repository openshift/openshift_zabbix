# == Class: ::openshift_zabbix::msgbus
#
# Configures monitoring scripts for an OpenShift Message Bus
#
# === Parameters
#
# None
#
# === Examples
#
#  include ::openshift_zabbix::msgbus
#
# === Copyright
#
# Copyright 2012 Red Hat, Inc., All rights reserved.
#
class openshift_zabbix::msgbus {
    include ::openshift_zabbix::libs

    $script_dir = '/usr/share/zabbix'
    $java_home  = '/usr/lib/jvm/java-1.7.0-openjdk'

    file {
        "${script_dir}/ActiveMQStats.java":
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/openshift_zabbix/checks/ActiveMQStats.java';

        "${script_dir}/check-activemq-stats":
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/openshift_zabbix/checks/check-activemq-stats';
    }

    cron { 'check-activemq-stats':
        ensure  => 'present',
        command => "${script_dir}/check-activemq-stats",
        minute  => '*/5',
        require => File["${script_dir}/check-activemq-stats"];
    }

    exec { 'javac_activemq_stats':
        command => "javac -cp #{$java_home}/lib/tools.jar #{$script_dir}/ActiveMQStats.java",
        creates => "#{$script_dir}/ActiveMQStats.class"
    }
}



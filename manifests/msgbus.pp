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
# Copyright 2012-2014 Red Hat, Inc., All rights reserved.
#
# === License
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
        command => "#{$java_home}/bin/javac -cp #{$java_home}/lib/tools.jar -d #{$script_dir} #{$script_dir}/ActiveMQStats.java",
        creates => "#{$script_dir}/ActiveMQStats.class"
    }
}



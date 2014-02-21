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
class openshift_zabbix::broker (
    $script_dir = '/usr/share/zabbix/bin'
) {
    ensure_resource('class', '::openshift_zabbix::libs', {
        script_dir => "${script_dir}/../lib"
    })

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

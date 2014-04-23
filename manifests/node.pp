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
class openshift_zabbix::node (
    $script_dir = '/usr/share/zabbix/bin'
) {
    include ::oo_ops::cmd::rand_sleep

    ensure_resource('class', '::openshift_zabbix::libs', {
        script_dir => "${script_dir}/../lib"
    })

    file { "${script_dir}/check-accept-node":
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/openshift_zabbix/checks/check-accept-node'
    }

    cron { 'check-accept-node':
        ensure  => 'present',
        command => "PATH=/sbin:\$PATH /usr/local/bin/rand_sleep 900 /usr/bin/flock -n /var/tmp/check-accept-node.lock -c ${script_dir}/check-accept-node",
        minute  => 0,
        hour    => [ 2,14 ],
        require => File["${script_dir}/check-accept-node"];
    }
}


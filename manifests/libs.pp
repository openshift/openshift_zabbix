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
class openshift_zabbix::libs {
    $script_dir = '/usr/share/zabbix'

    file { "${script_dir}/lib":
        ensure       => directory,
        source       => 'puppet:///modules/openshift_zabbix/lib',
        recurse      => true,
        recurselimit => 2;
    }
}

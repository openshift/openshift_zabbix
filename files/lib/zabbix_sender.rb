#   Copyright 2012 Red Hat Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#  Purpose: provide a standardized interface to use zabbix_sender
#
require 'facter'
require 'tempfile'
require 'fileutils'
require 'thread'
require 'json'

require_relative './utils/log'

ZabbixSenderEntry = Struct.new(:target_host, :item_key, :item_value)

class ZabbixSender
  attr_reader :zabbix_server, :rundir, :sender, :fqdn, :entries, :lock

  def initialize(server, args = {})
    @zabbix_server = server
    @zabbix_port   = args[:port]   || 10051
    @rundir        = args[:rundir] || '/var/run/zabbix'
    @sender        = args[:sender] || '/usr/bin/zabbix_sender'
    @fqdn          = args[:fqdn]   || Facter.fact('fqdn').value
    @log           = args[:log]    || Log.new
    @entries       = []
    @lock          = Mutex.new

    FileUtils.mkdir_p(@rundir) unless File.directory?(@rundir)
  end

  def add_entry(item_key, item_value, target_host=@fqdn)
    @lock.synchronize do
      @entries << ZabbixSenderEntry.new(target_host, item_key, item_value)
    end
  end

  # This creates items for low level discovery in zabbix.
  # See: https://www.zabbix.com/documentation/2.0/manual/discovery/low_level_discovery
  #
  # This will create json in the format as:
  # "{\"data\":[{\"{#macro_strin}\":\"macro_array[0]\"},{\"{#macro_string}\":\"macro_array[1]\"}]}"
  def create_dynamic_item(discover_key, macro_string, macro_array, target_host=@fqdn)
    @lock.synchronize do
      inner_array = []
      macro_array.each { |x| inner_array << { macro_string => x } }
      json_hash = { "data" => inner_array }
      json_items = json_hash.to_json

      @entries << ZabbixSenderEntry.new(target_host, discover_key, json_items)
    end
  end

  def send_data(verbose=true)
    @log << "Sending:" if verbose

    # Create a temporary file for this class (where the data is stored)
    tmpfile = Tempfile.new(self.class.name, "#{@rundir}/")
    @entries.each do |entry|
      line = "#{entry.target_host} #{entry.item_key} #{entry.item_value}"

      @log << line if verbose
      tmpfile << line
    end
    tmpfile.close()

    cmd = "#{@sender} -z #{@zabbix_server} -i #{tmpfile.path}"
    cmd += " -vv" if verbose
    cmd += " &> /dev/null" unless verbose

    system(cmd)
    retval = $?.exitstatus

    tmpfile.unlink

    return retval
  end
end

__END__

# Copyright 2012 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Purpose: Provide basic cli options for Zabbix scripts
#

require 'optparse'
require_relative './config'

class CLIOpts
  attr_reader :zero, :args, :options
  attr_accessor :optparser

  DefaultConfigFile = '/etc/openshift/openshift_zabbix.conf'

  DefaultOptions = {
    :verbose => false,
    :server  => 'localhost',
    :port    => 10050,
    :user    => 'admin',
    :passwd  => 'zabbix'
  }

  def initialize(zero=$0, args=ARGV, config_file=DefaultConfigFile)
    @zero = zero
    @args = args

    init_config(config_file)
    init_opts
  end

  #
  # Pass-through to allow consumers to add their own options
  #
  def on(*args, &block)
    @optparser.on(*args, &block)
  end

  #
  # Pass-through to delay parsing args until consumers have had a chance to add
  # their own options
  #
  def parse
    @optparser.parse(@args)
  end

  private

  #
  # Enable options to be set via config file or CLI.
  # CLI options will take precedence if both are used.
  #
  def init_config(cfg)
    conf     = ConfigFile.new(cfg).get
    @options = DefaultOptions
    @options.merge!(conf).map { |k,v| [k.to_sym, v]}
  end

  def init_opts
    @optparser = OptionParser.new { |opts|
      opts.banner = "Usage: #{@zero} [options]"
      opts.separator ''

      opts.on('-h', '--help', 'Show this message') {
        puts opts
        exit 1
      }
      opts.on('-v', '--[no-]verbose', 'Change verbosity') { |x| @options[:verbose] = x }
      opts.on('-t', '--test', "Test the script. Skip sending data to Zabbix server") { |x| @options[:test] = x }
      opts.separator ''
      opts.on('-f', '--file PATH', String, 'Optional YAML configuration file (default: /etc/openshift/openshift_zabbix.conf)') { |x|
        init_config(x)
        @options[:configfile] = x
      }
      opts.separator ''
      opts.on('-s', '--server SERVER', 'Zabbix server hostname (default: localhost)') { |x| @options[:server] = x }
      opts.on('-p', '--port PORT', 'Zabbix server port (default: 10050)') { |x| @options[:port] = x }
      opts.on('--user USER', 'Zabbix server login username (default: "admin")') { |x| @options[:user] = x }
      opts.on('--password USER', 'Zabbix server login password (default: "zabbix")') { |x| @options[:passwd] = x }
      opts.separator ''
    }
  end
end

__END__

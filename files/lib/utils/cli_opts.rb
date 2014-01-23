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

class CLIOpts
  attr_reader :zero, :args, :options
  attr_accessor :optparser

  def initialize(zero=$0, args=ARGV)
    @zero = zero
    @args = args

    @options = {
      :verbose => false,
      :server  => 'localhost',
      :port    => 10050,
      :user    => 'admin',
      :passwd  => 'zabbix'
    }

    init_opts
  end

  def on(*opts, &block)
    @optparser.on(args, block)
  end

  def parse
    @optparser.parse(@args)
  end

  private

  def init_opts
    @optparser = OptionParser.new { |opts|
      opts.banner = "Usage: #{@zero} [options]"
      opts.separator ''

      opts.on('-h', '--help', 'Show this message') {
        puts opts
        exit 1
      }
      opts.on('-v', '--[no-]verbose', 'Change verbosity') { |x|
        @options[:verbose] = x
      }
      opts.on('-s', '--server', 'Zabbix server hostname (default: localhost)') { |x|
        @options[:server] = x
      }
      opts.on('-p', '--port', 'Zabbix server port (default: 10050)') { |x|
        @options[:port] = x
      }
      opts.on('--user', 'Zabbix server login username (default: "admin")') { |x|
        @options[:user] = x
      }
      opts.on('--password', 'Zabbix server login password (default: "zabbix")') { |x|
        @options[:passwd] = x
      }
    }
  end
end

__END__

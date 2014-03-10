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
# Purpose: Abstract away the ugliness of logging because Ruby insists on having
#     Logger and Syslog be separate modules with completely different semantics.
#

require 'logger'
require 'syslog'
require 'ostruct'

class Log
  attr_accessor :stdout, :stderr, :syslog, :file, :output, :severity

  #
  # out = selector for where to output logs.
  #     values - :stdout, :stderr, :file, :syslog
  #
  # sev = severity level
  #     values - :fatal, :error, :warn, :info, :debug, :unknown
  #
  # filename = filename used when logging to a file
  #
  def initialize(out=:stdout,sev=:info,filename=nil)
    @stdout   = Logger.new(STDOUT)
    @stderr   = Logger.new(STDERR)
    @file     = Logger.new(filename) unless filename.nil?

    @syslog   = Syslog.open($0, Syslog::LOG_PID, Syslog::LOG_USER)
    @syslog.close # Don't hold the handle open. We'll reopen as-needed.

    @output   = out
    @severity = sev
  end

  def close
    @stdout.close
    @stderr.close
    @file.close
    @syslog.close
  end

  def file=(filename)
    @file.close unless @file.nil?
    @file = Logger.new(filename)
    # let's assume if you're setting a filename, you want to use that as the log. :)
    @output = :file
  end

  #
  # Here, we figure out where the desired log destination is, map that to the
  # appropriate ruby library, correct method semantics, and correct severity
  # names.
  #
  # Ugly, but effective.
  #
  def puts(msg, sev=@severity)
    if @@output_map[@output] == :logger
      eval "#{@output.to_s}.#{map_output.log_method.to_s}(#{map_severity(sev)}) { msg }"
    elsif @@output_map[@output] == :syslog
      @syslog.open($0, Syslog::LOG_PID, Syslog::LOG_USER) unless @syslog.opened?
      eval "#{@output.to_s}.#{map_output.log_method.to_s}(#{map_severity(sev)}, msg)"
      @syslog.close
    end
  end

  def <<(msg,sev=@severity)
    self.puts(msg,sev)
  end

  def debug(msg)
    self.puts(msg,:debug)
  end

  def info(msg)
    self.puts(msg,:info)
  end

  def warn(msg)
    self.puts(msg,:warn)
  end

  def error(msg)
    self.puts(msg,:error)
  end

  def fatal(msg)
    self.puts(msg,:fatal)
  end

  private

  # Class methods to enable mapping a common nomenclature to the two logging modules
  @@syslog = OpenStruct.new(
    :log_method => :log,
    :fatal      => Syslog::LOG_CRIT,
    :error      => Syslog::LOG_ERR,
    :warn       => Syslog::LOG_WARNING,
    :info       => Syslog::LOG_INFO,
    :debug      => Syslog::LOG_DEBUG,
    :unknown    => Syslog::LOG_ALERT
  )

  @@logger = OpenStruct.new(
    :log_method => :add,
    :fatal      => Logger::FATAL,
    :error      => Logger::ERROR,
    :warn       => Logger::WARN,
    :info       => Logger::INFO,
    :debug      => Logger::DEBUG,
    :unknown    => Logger::UNKNOWN
  )

  @@output_map = {
    :stdout => :logger,
    :stderr => :logger,
    :file   => :logger,
    :syslog => :syslog
  }

  # helper methods to jump through the necessary hoops
  def map_output
    eval "@@#{@@output_map[@output].to_s}"
  end

  def map_severity(sev)
    eval "map_output.#{sev}"
  end
end

__END__

l = Log.new()
l << 'msg'
l.puts 'msg'
l.syslog.log(Syslog::LOG_DEBUG, 'msg')
l.stderr.warn('msg')
l.debug('msg')

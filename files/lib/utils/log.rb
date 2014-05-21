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

# This formatter is for stdout, where we don't want timestamps or other
# fancy decorations.
class PlainFormatter < Logger::Formatter
  def call(severity, time, progname, msg)
    msg2str(msg) + "\n"
  end
end

class Log
  attr_accessor :stdout, :stderr, :syslog, :file, :output, :severity, :threshold

  #
  # out = selector for where to output logs.
  #     values - :stdout, :stderr, :file, :syslog
  #
  # sev = the default severity level at which messages are logged
  #     values - :fatal, :error, :warn, :info, :debug, :unknown
  #
  # filename = filename used when logging to a file
  #
  def initialize(out=:stdout,threshold=:info,filename=nil,sev=:info)
    @stdout   = Logger.new(STDOUT)
    @stdout.formatter = PlainFormatter.new
    @stderr   = Logger.new(STDERR)
    @stderr.formatter = PlainFormatter.new
    @file     = Logger.new(filename) unless filename.nil?
    set_threshold(threshold)

    @syslog   = Syslog.open($0, Syslog::LOG_PID, Syslog::LOG_USER)
    @syslog.close # Don't hold the handle open. We'll reopen as-needed.

    if out.is_a?(Array)
      @output   = out
    else
      @output   = [out]
    end
    @severity = sev
  end

  # This is an alias so that the threshold for
  # all loggers can be set with one assignment
  def threshold=(level=:info)
    set_threshold(level)
  end

  # Set log level for one of more loggers
  def set_threshold(level=:info, out=:all)
    case out
    when :all
      @stdout.level = map_severity(:stdout, level)
      @stderr.level = map_severity(:stderr, level)
      @file.level = map_severity(:file, level) unless @file.nil?
    when :stdout
      @stdout.level = map_severity(:stdout, level)
    when :stderr
      @stderr.level = map_severity(:stderr, level)
    when :file
      @file.level = map_severity(:file, level)
    else
      raise "invalid logger specified"
    end
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
    @output.each { |out| write_log(msg, sev, out) }
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

  def write_log(msg, sev, dest)
    if @@output_map[dest] == :logger
      eval "#{dest.to_s}.#{self.class.map_output(dest).log_method.to_s}(#{map_severity(dest, sev)}) { msg }"
    elsif @@output_map[dest] == :syslog
      @syslog.open($0, Syslog::LOG_PID, Syslog::LOG_USER) unless @syslog.opened?
      eval "#{dest.to_s}.#{self.class.map_output(dest).log_method.to_s}(#{map_severity(dest, sev)}, msg)"
      @syslog.close
    end
  end

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
  def self.map_output(o)
    eval "@@#{@@output_map[o].to_s}"
  end

  def map_severity(o, sev)
    eval "self.class.map_output(o).#{sev}"
  end
end

__END__

l = Log.new()
l << 'msg'
l.puts 'msg'
l.syslog.log(Syslog::LOG_DEBUG, 'msg')
l.stderr.warn('msg')
l.debug('msg')

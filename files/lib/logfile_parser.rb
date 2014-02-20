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
# This file inspired by:
# http://smyck.net/2011/02/12/parsing-large-logfiles-with-ruby/
#
# Purpose: Enable quick searching for sections of a log file based on date.

class LogFileParser
  include Enumerable

  attr_accessor :buffer_size, :byte_offset, :start_time
  attr_accessor :log, :file_size

  def initialize(fname, start_time=(Time.now-3600).to_i)
    raise ArgumentError unless (File.exists?(fname) and File.readable?(fname))

    @log         = File.open(fname, 'r')
    @start_time  = start_time
    @buffer_size = 32 * 1024
    @byte_offset = @buffer_size
  end

  # The idea here is to approximate the amount of lines and time covered by
  # @byte_offset. Then, we calculate how many offsets into the file we need
  # to begin looking for new lines.
  #
  def find_pos
    @log.seek(0) unless @log.pos == 0
    buff = @log.read(@buffer_size)
    buff_lines = buff.split("\n")

    start_line = nil
    buff_lines.each do |line|
        if line =~ /TIMESTAMP=\d{10}/
            start_line = line
            break
        end
    end
    raise "Incorrect input data for begin_date." if start_line.nil?

    end_line = nil
    buff_lines.reverse.each do |line|
        if line =~ /TIMESTAMP=\d{10}/
            end_line = line
            break
        end
    end
    raise "Incorrect input data for start_diff date." if end_line.nil?

    begin_date = parse_date(start_line)
    start_diff = parse_date(end_line) - begin_date

    if (@start_time <= begin_date)
      @log.seek(0) unless @log.pos == 0
    else
      @log.seek(-@byte_offset, File::SEEK_END)
      buff = @log.read(@buffer_size)
      buff_lines = buff.split("\n")

      end_diff = parse_date(end_line) - parse_date(start_line)

      # assuming a reasonably steady rate of logging, this should get us
      # close to the location of log lines we care about.
      time_avg = (start_diff + end_diff) / 2
      num_offsets = validate_offset(((@start_time - begin_date) / time_avg) - 1)

      @log.seek((num_offsets*@byte_offset), File::SEEK_SET)

      # back up if we've over-estimated.
      while parse_date(@log.read(@buffer_size).split("\n")[1]) > @start_time
        num_offsets = validate_offset((num_offsets-1))
        @log.seek((num_offsets*@byte_offset), File::SEEK_SET)
      end

      @log.seek((num_offsets*@byte_offset), File::SEEK_SET)
    end
  end

  def validate_offset(offset)
    offset = 0 if offset < 0
    filesize = @log.stat.size
    offset = (filesize/@byte_offset) if (offset*@byte_offset) > filesize

    return offset
  end

  # TODO: This is specific to the user_action.log format.
  # TODO: It really should be changed to be more general-purpose.
  def parse_date(line)
    re = /TIMESTAMP=(\d{10})/
    m = re.match(line)

    if m
      return m[1].to_i
    end

    return nil
  end

  def each(&block)
    find_pos

    @log.each_line do |line|
      yield line
    end
  end
end

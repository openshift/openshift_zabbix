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

  @@timestamp_re = /TIMESTAMP=(\d{10})/
  @@datetime_re  = /DATE=(\d{4}-\d{2}-\d{2}) TIME=(\d{2}:\d{2}:\d{2})/

  def initialize(fname, start_time=(Time.now-3600).to_i)
    raise ArgumentError unless (File.exists?(fname) and File.readable?(fname))

    @log         = File.open(fname, 'rb:UTF-8')
    @start_time  = start_time
    @buffer_size = 128 * 1024
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
        if line =~ @@timestamp_re
            start_line = line
            break
        end
    end
    raise "Incorrect input data for begin_date." if start_line.nil?

    end_line = nil
    buff_lines.reverse.each do |line|
        if line =~ @@timestamp_re
            end_line = line
            break
        end
    end
    raise "Incorrect input data for start_diff date." if end_line.nil?

    begin_date = parse_date(start_line)
    start_diff = parse_date(end_line) - begin_date

    if ((@start_time <= begin_date) or (File.size(@log) < @byte_offset))
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

      lines = @log.read(@buffer_size).split("\n")
      date_line = lines.find { |l| l =~ @@timestamp_re }
      date      = parse_date(date_line)

      # back up if we've over-estimated.
      while date.nil? or date > @start_time
        num_offsets = validate_offset((num_offsets-1))
        @log.seek((num_offsets*@byte_offset), File::SEEK_SET)

        chunk = @log.read(@buffer_size)
        date  = chunk.nil? ? nil : parse_date(chunk.split("\n")[1])

        # avoid endlessly looping if we're at the beginning of the file.
        break if date.nil? and num_offsets == 0
      end
    end
  end

  def validate_offset(offset)
    offset = 0 if offset < 0
    offset = (@log.size/@byte_offset) if (offset*@byte_offset) > @log.size
    return offset
  end

  def parse_date(line)
    m = @@timestamp_re.match(line)

    if m
      return m[1].to_i
    else
      m = @@datetime_re.match(line)
      if m
        d = DateTime.strptime("#{m[1]} #{m[2]}", "%Y-%m-%d H:%M:%S")
        return d.strftime("%s")
      end
    end

    return nil
  end

  def each(&block)
    return nil if @log.size == 0

    find_pos

    @log.each_line do |line|
      yield line
    end
  end
end

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
# Purpose: utility class to manage stored state for scripts

class StateFile
  attr_reader :filename, :state

  def initialize(filename)
    @filename = filename
  end

  #
  # Public: load state data from Marshalled file
  #
  def load
    begin
      fh = File.open(@filename, 'r')
      @state = Marshal.load(fh)
      fh.close
    rescue => e
      raise e
    end
    return @state || []
  end

  #
  # Public: write state data to Marshalled file
  #
  def save(state=@state)
    begin
      fh = File.open(@filename, 'w')
      fh.write(Marshal.dump(state))
      fh.close
    rescue => e
      raise e
    end
  end
end

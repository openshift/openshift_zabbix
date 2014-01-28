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
# Purpose: Reads a YAML config file. Nothing too fancy.

require 'yaml'

class ConfigFile
  attr_accessor :filename, :config

  def initialize(filename)
    @filename = filename
    load_config
  end

  def get
    load_config if @config.nil?
    return @config
  end

  private

  def load_config
    if File.exists?(@filename) and File.readable?(@filename)
      @config = YAML::load_file(@filename)
    else
      @config = Hash.new(nil)
    end
  end

end

__END__

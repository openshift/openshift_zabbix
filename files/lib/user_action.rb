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
# Purpose: Model a line from the OpenShift broker's user_action.log
#

require_relative './utils/log'

#
# Public: Class to parse lines from user_action.log into minable data objects
#
# Examples
#
# ua = UserAction.new(line)
#
# ua = UserAction.new('SUCCESS DATE=1970-01-01 TIME=12:01:01 ACTION=LEGACY_USER_INFO REQ_ID=1234567890abcdef1234567890abcdef USER_ID=1234567890abcdef1234567890abcdef LOGIN=foo@bar.com')
#
class UserAction
    attr_accessor :result, :timestamp, :action, :request_id, :user_id
    attr_accessor :login, :message, :line, :error_count, :debug

    USER_ACTION_LOG_FILE= '/var/log/openshift/broker/openshift-broker.log'

    @@line_regex = Regexp.new('.* RESULT=(?<result>(SUCCESS|FAILURE)) STATUS=(?<status>\S*) TIMESTAMP=(?<timestamp>\d{10}) DATE=(?<date>\d{4}-\d{2}-\d{2}) TIME=(?<time>\d{2}:\d{2}:\d{2}) ACTION=(?<action>\S*) REQ_ID=(?<request_id>\S*) USER_ID=(?<user_id>\S*) LOGIN=(?<login>\S*) (?<message>.*)$')

    def initialize(line, debug=false, log=Log.new)
        @error_count = 0
        @debug       = debug
        @line        = line
        @log         = log

        x = @@line_regex.match(line)
        if x
            @result     = x['result']
            @timestamp  = x['timestamp'].to_i
            @action     = x['action']
            @request_id = x['request_id']
            @user_id    = x['user_id']
            @login      = x['login']
            @message    = x['message']
        else
            @log << "Problem parsing: #{line}" if @debug
            @error_count += 1
        end
    end

    def to_s
      if @debug
        return "#{super.to_s}: #{@line}"
      else
        return "#{super.to_s}"
      end
    end
end


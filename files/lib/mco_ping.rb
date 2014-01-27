#   Copyright 2013 Red Hat Inc.
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
# Purpose: facilitate mco pings
#
class MCOPing
    def self.get_mc_ping_hosts()
        # don't output errors from /usr/bin/timeout
        orig_stderr = $stderr.clone
        $stderr.reopen("/dev/null", "w")

        #FIXME: there ought to be a way to hook into the MCollective libraries
        #FIXME: directly to do this.
        raw = %x[/usr/bin/timeout -s9 30s /opt/rh/ruby193/root/usr/sbin/mco ping --dt 10 -t 15 2>/dev/null].split("\n")

        # reset stderr back
        $stderr.reopen(orig_stderr)

        # filter out only the hosts lines
        raw.delete_if { |host| host !~ /time=.*ms/ }

        # extract only the host names from the line
        hosts = raw.collect { |line| line.split()[0] }

        return hosts
    end
end

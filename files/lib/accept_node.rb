#   Copyright 2012 Red Hat Inc.
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
require 'tempfile'
require_relative './utils/log'

class AcceptNode
  attr_accessor :output, :verbose, :exitcode

  @@accept_node = '/usr/sbin/oo-accept-node'

  def initialize(verbose=false)
    @verbose = verbose
    @log     = Log.new(:syslog)
  end

  def run
    tmpfile = Tempfile.new(self.class.name)

    if @verbose
      cmd = "/usr/bin/env oo-ruby -E UTF-8:UTF-8 #{@@accept_node} -v 2>&1 | /usr/bin/tee #{tmpfile.path} ; exit ${PIPESTATUS[0]}"
      @log.stdout.debug("Running: #{cmd}\n\n")
    else
      cmd = "/usr/bin/env oo-ruby -E UTF-8:UTF-8 #{@@accept_node} -v > #{tmpfile.path} 2>&1"
    end

    system(cmd)
    @exitcode = $?.exitstatus
    @output = File.read(tmpfile.path)
    @log.stdout.debug("Exit Code: #{@exitcode}") if @verbose
  end

  def cgroup_reclassify
    uuids = []
    @output.split("\n").each do |line|
      uuids << $1.strip if line =~ /^FAIL:(.*)has a process missing from cgroups/
    end

    uuids.uniq.each do |uuid|
      # Skip any invalid gear uuids
      next unless valid_gear_uuid?(uuid)

      cmd = "/usr/bin/oo-cgroup-reclassify --with-container-uuid #{uuid}"
      msg = "Cleaning up cgroups by running: #{cmd}"
      exec_cmd(cmd, msg)
    end
  end

  # bug https://bugzilla.redhat.com/show_bug.cgi?id=1020555
  def restart_gear
    uuids = []
    @output.split("\n").each do |line|
      uuids << $1.strip if line =~ /^FAIL:(.*)has a process missing from cgroups/
    end

    uuids.uniq.each do |uuid|
      # Skip any invalid gear uuids
      next unless valid_gear_uuid?(uuid)

      cmd = "/usr/sbin/oo-admin-ctl-gears stopgear #{uuid}"
      msg = "Cleaning up cgroups by running: #{cmd}"
      exec_cmd(cmd, msg)

      #FIXME: replace with Process.kill(), if possible
      cmd = "/usr/bin/killall -9 -u #{uuid}"
      msg = "Killing all user processes by running: #{cmd}"
      exec_cmd(cmd, msg)

      cmd = "/usr/sbin/oo-admin-ctl-gears restartgear #{uuid}"
      msg = "Cleaning up cgroups by running: #{cmd}"
      exec_cmd(cmd, msg)
    end
  end

  def kill_unowned_procs
    pids = []
    @output.split("\n").each do |line|
      pids << $1.strip.to_i if line =~ /^FAIL: Process (\d+) is owned by a gear that's no longer on the system, uid:/
      pids << $1.strip.to_i if line =~ /^FAIL: Process (\d+) exists for uid (\d+); uid is in the gear uid range but not a gear user/
    end

    pids.each do |pid|
      # Skip unless pid is valid
      next unless pid.is_a?(Fixnum) && pid >= 2

      msg = "Cleaning up unowned gear processes by sending SIGKILL to pid #{pid}"
      @log.stdout.debug(msg) if @verbose
      @log << msg
      Process.kill('KILL', pid)
    end
  end

  def fix_missing_frontend
    uuids = []
    @output.split("\n").each do |line|
      uuids << $3.strip if line =~ /^FAIL: Gear has a (web|websocket) framework cartridge but no (Apache|websocket) configuration: (.*)$/
    end

    uuids.uniq.each do |uuid|
      # Skip any invalid gear uuids
      next unless valid_gear_uuid?(uuid)

      cmd = "/usr/bin/rhc-fix-missing-frontend -b #{uuid}"
      msg = "Cleaning up missing frontend by running: #{cmd}"
      exec_cmd(cmd, msg)
    end
  end

  def restart_mcollective
    if @output =~ /^FAIL: (no manifest in the cart repo matches|error with manifest file|cart repo version is older than)/
      cmd = "/sbin/service mcollective restart"
      msg = "Cleaning up manifest by running: #{cmd}"
      exec_cmd(cmd, msg)
    end
  end

  def restart_cgred
    if @output =~ /^FAIL: service cgred not running/
      cmd = "/sbin/service cgred restart"
      msg = "Restarting cgred by running: #{cmd}"
      exec_cmd(cmd, msg)
    end
  end

  def remove_partially_deleted_gears
    uuids = []
    @output.split("\n").each do |line|
      uuids << $1.strip if line =~ /^FAIL: directory (.*) doesn't have (an associated user|a cartridge directory)/
    end

    uuids.uniq.each do |uuid|
      if gear_deleted?(uuid)
        Dir.chdir("/var/lib/openshift") do
          if File.exists?(uuid)
            dir_size = %x[du -s #{uuid}].split()[0].to_i
            # Make sure uuid dir is > 0 (because to_i returns 0 on failure)
            # and < 100k before deleting
            @log.stdout.debug "#{uuid} directory size: #{dir_size}K" if @verbose
            if dir_size > 0 && dir_size < 100
              msg = "PWD: #{Dir.pwd}, Cleaning up partially deleted gear by removing /var/lib/openshift/#{uuid}"
              @log.stdout.debug(msg) if @verbose
              @log << msg
              FileUtils.rm_rf(uuid, :secure=>true)
            end
          end
        end
      end
    end
  end

  private

  def exec_cmd(cmd, msg)
    cmd += " &>/dev/null" unless @verbose
    @log.stdout.debug(msg) if @verbose
    @log << msg
    system(cmd)
  end

 
  def file_grep?(filename,uuid)
    file = nil
    if filename =~ /\.gz|zip/
       require 'zlib'
       file = Zlib::GzipReader.open(filename) 
    elsif filename =~ /\.zip/
       require 'zip/zip'
       file = Zip::ZipFile.open(filename)
    elsif filename =~ /\.bz2/
       raise "Unsupported Compression: bzip2"
    else
       file = File.open(filename)
    end
    return file.grep(/(app-destroy|oo_app_destroy).*#{uuid}/).any?
  end

  def gear_deleted?(uuid)
    # If the gear is invalid, then clearly it couldn't have been deleted
    return false unless valid_gear_uuid?(uuid)

    @log.stdout.debug "Checking if gear #{uuid} has been deleted from the system... " if @verbose

    mco_logs = ['/var/log/mcollective.log'] + Dir.glob("/var/log/mcollective*.gz")
    mco_logs.each do |logfile| 
        if file_grep?(logfile, uuid)
            @log.stdout.debug "Gear has been deleted." if @verbose
            return true
        end
    end
    # if it gets this far, gear has not been deleted
    @log.stdout.debug "Gear has NOT been deleted." if @verbose
    return false
  end

  def valid_gear_uuid?(uuid)
    @log.stdout.debug "Checking if gear #{uuid} is a valid format... " if @verbose
    if uuid.size >= 24 && ( uuid =~ /\A[a-z0-9]{32}\z/  ||  uuid =~ /\A[a-z0-9]{24}\z/ )
      @log.stdout.debug "Gear has a valid format." if @verbose
      return true
    else
      @log.stdout.debug "Gear does NOT have a valid format." if @verbose
      return false
    end
  end

end

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

require 'mcollective'
include MCollective::RPC

class OpenShiftMCollective

  DefaultTimeout = {
    :discovery => 10,
    :general   => 10,
    :max_call  => 20
  }

  #
  # args = {
  #   :hosts        => String | Array,
  #   :agent        => String,
  #   :verbose      => Boolean,
  #   :disc_timeout => Integer,
  #   :timeout      => Integer,
  #   :call_timout  => Integer
  # }
  #
  def initialize(args={})
    if args[:hosts].kind_of? String
      @hosts = args[:hosts].split(',')
    elsif args[:hosts].kind_of? Array
      @hosts = args[:hosts]
    elsif args[:hosts].nil?
      # no op. nil will ping all hosts.
    else
      raise ":hosts must be String or Array or nil"
    end

    agent   = args[:agent]   || 'openshift'
    verbose = args[:verbose] || false

    options               = MCollective::Util.default_options
    options[:verbose]     = verbose             || false
    options[:disctimeout] = args[:disc_timeout] || DefaultTimeout[:discovery]
    options[:timeout]     = args[:timeout]      || DefaultTimeout[:general]
    @max_call_timeout     = args[:call_timeout] || DefaultTimeout[:max_call]

    @mc = rpcclient(agent, {:options => options})

    if @hosts.nil?
      @mc.discover()
    else
      @mc.discover(:nodes => @hosts)
    end

    @mc.progress = verbose
  end

  def get_nodes_facts(facts=[], verbose=false)
    if facts.kind_of? String
      facts = facts.split(',')
    elsif facts.kind_of? Array
      # no op
    else
      raise 'facts must be String or Array'
    end

    retval = nil

    Timeout::timeout(@max_call_timeout) do
      mc_args = { :facts => facts }
      retval  = @mc.get_facts(mc_args)
    end

    return retval
  end
end

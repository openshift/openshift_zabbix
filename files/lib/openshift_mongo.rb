
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
#  Purpose: provide a standardized interface to interact with OpenShift's mongo
#  collections
#
require 'rubygems'
require 'mongo'

class OpenShiftMongo
  attr_accessor :config, :broker_db, :district_col, :user_col

  CONF_FILE='/etc/openshift/broker.conf'

  def initialize(config)
    @config = config

    client = Mongo::MongoReplicaSetClient.new(@config[:host_port])

    @broker_db = client[@config[:db]]
    @broker_db.authenticate(@config[:user], @config[:password])

    @district_col = @broker_db.collection(@config[:collections][:district])
    @user_col     = @broker_db.collection(@config[:collections][:user])
  end

  def get_district_nodes()
    hosts = []

    @district_col.find().each do |district|
      district['server_identities'].each do |node|
        hosts << node['name']
      end
    end

    return hosts
  end

  def get_district_by_name(name)
    return @district_col.find("name" => name).collect { |d| d }
  end

  def get_all_districts()
    return @district_col.find().collect { |district| district }
  end

  def get_all_users()
    return @user_col.find()
  end

  def self.get_broker_mongo_config()
    conf = {}
    #FIXME: there's got to be a better way...
    File.foreach(CONF_FILE) do |line|
      next unless line =~ /[A-Z]+=.*/

      key,value = line.split('=')
      conf[key.strip()] = value.gsub('"','').gsub("'",'').strip()
    end

    retval = {
      :replica_set => true,
      :db          => conf["MONGO_DB"],
      :user        => conf["MONGO_USER"],
      :password    => conf["MONGO_PASSWORD"],
      :host_port   => conf["MONGO_HOST_PORT"].split(','),

      # This one is hard coded because it's no longer in a conf file
      :collections => {
        :district         => "districts",
        :distributed_lock => "distributed_locks",
        :user             => "cloud_users"
      }
    }
    return retval
  end
end

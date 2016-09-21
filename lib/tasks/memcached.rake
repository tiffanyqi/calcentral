require 'calcentral_config'
require 'net/telnet'
require 'date'
require 'pp'

namespace :memcached do

  desc 'Fetch memcached stats from all cluster nodes'
  task :get_stats => :environment do
    pp Memcached.all_stats
  end

  desc 'Invalidate all memcached keys and reset stats'
  task :clear => :environment do
    pp Memcached.clear_all
  end

  desc 'Take a closer look at how one memcached slab is being used'
  task :dump_slab  => :environment do
    slab = ENV['slab']
    if slab.blank?
      Rails.logger.error 'Must specify slab="a_slab_number"'
    else
      pp Memcached.dump_slab_on_all slab
    end
  end
end

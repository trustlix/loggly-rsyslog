#
# Cookbook Name:: loggly
# Recipe:: default
#
# Copyright (C) 2014 Matt Veitas
#
# All rights reserved - Do Not Redistribute
#

loggly_token = data_bag_item(node['loggly']['application'], 'loggly')['token']
raise "No token was found in the loggly databag." if loggly_token.nil?

service "rsyslog" do
  # Force Upstart provider on ubuntu to avoid bug 
  # https://bugs.launchpad.net/openstack-chef/+bug/1313646
  # on older Chef versions
  case node["platform"]
  when "ubuntu"
    if node["platform_version"].to_f >= 9.10
      provider Chef::Provider::Service::Upstart
    end
  end
end

include_recipe "loggly-rsyslog::tls" if node['loggly']['tls']['enabled']

template '/etc/rsyslog.conf' do
  source 'loggly.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables({
    :monitor_files => !node['loggly']['log_files'].empty? || !node['loggly']['log_dirs'].empty?,
    :tags => node['loggly']['tags'].nil? || node['loggly']['tags'].empty? ? '' : "tag=\\\"#{node['loggly']['tags'].join("\\\" tag=\\\"")}\\\"",
    :token => loggly_token
  })
  notifies :restart, "service[rsyslog]", :immediate
end

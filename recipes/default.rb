#
# Cookbook Name:: loggly
# Recipe:: default
#
# Copyright (C) 2014 Matt Veitas
#
# All rights reserved - Do Not Redistribute
#

loggly_token = data_bag_item(node['loggly']['application'], 'loggly')['token']
raise 'No token was found in the loggly databag.' if loggly_token.nil?

service 'rsyslog' do
  provider Chef::Provider::Service::Upstart if platform?('ubuntu') && node['platform_version'].to_f >= 13.10
  action :nothing
end

template '/etc/default/rsyslog' do
  source 'rsyslog-defaults.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    :debug => node['loggly']['debug']
  })
end

include_recipe 'loggly-rsyslog::tls' if node['loggly']['tls']['enabled']

template '/etc/rsyslog.d/10-loggly.conf' do
  source 'loggly.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables({
    :monitor_files => !node['loggly']['log_files'].empty? || !node['loggly']['log_dirs'].empty?,
    :tags => node['loggly']['tags'].nil? || node['loggly']['tags'].empty? ? '' : "tag=\\\"#{node['loggly']['tags'].join("\\\" tag=\\\"")}\\\"",
    :token => loggly_token
  })
end

group 'www-data' do
  members 'syslog'
  append true
  notifies :restart, 'service[rsyslog]', :delayed
end

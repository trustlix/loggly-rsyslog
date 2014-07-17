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
  provider Chef::Provider::Service::Upstart if platform?("ubuntu") && node["platform_version"].to_f >= 13.10
end

group "www-data" do
  action :modify
  members "syslog"
  append true
end

include_recipe "loggly-rsyslog::tls" if node['loggly']['tls']['enabled']

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
  notifies :restart, "service[rsyslog]", :immediate
end

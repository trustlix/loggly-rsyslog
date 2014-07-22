#
# Cookbook Name:: loggly
# Recipe:: rsyslog
#

service 'rsyslog' do
  provider Chef::Provider::Service::Upstart if platform?('ubuntu') && node['platform_version'].to_f >= 13.10
  action :nothing
end

template '/etc/rsyslog.conf' do
  source 'rsyslog.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables({
    :drop_privilege_user => node['loggly']['rsyslog']['drop_privilege_user'],
    :drop_privilege_group => node['loggly']['rsyslog']['drop_privilege_group']
  })
end

template '/etc/default/rsyslog' do
  source 'rsyslog-defaults.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    :debug => node['loggly']['rsyslog']['debug']
  })
end

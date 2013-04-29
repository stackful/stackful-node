#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
node_user = settings["user"]
node_group = settings["group"]
node_user_home = "/home/#{node_user}"
app_home = settings["app-home"]
app_name = settings["app-name"]
install_demo_marker = File.join(app_home, "install-demo")
config_file = File.join("/etc", "stackful", "node.json")
demo_repo = settings["demo-repo"]
upstart_config = "/etc/init/node-web.conf"
git_settings = node["stackful-git"]
deploy_user = git_settings["deploy-user"]
deployer_home = git_settings["deployer-home"]
#####################################################################

group node_group
user node_user do
  gid node_group
  home node_user_home
end

directory node_user_home do
  owner node_user
  group node_group
  mode 00755
end

group "stackful" do
  members [node_user]
  append true
end

execute "secure node config" do
  command "chgrp stackful '#{config_file}' && chmod 660 '#{config_file}'"
end

execute "install meteorite" do
  command "npm install meteorite -g"
  not_if "which mrt"
end

execute "create app home" do
  command <<-EOCOMMAND
mkdir -p '#{app_home}' && \
chown -R #{node_user}:#{node_group} '#{app_home}'
EOCOMMAND

  notifies :run, "execute[demo app install]"
  not_if { ::File.exists?(app_home) }
end

execute "demo app install" do
  action :nothing
  user node_user
  group node_group
  cwd "/tmp"

  command <<-EOCOMMAND
git clone https://github.com/stackful/#{demo_repo}.git '#{app_home}' && \
rm -rf '#{app_home}/.git'
EOCOMMAND
  notifies :run, "execute[deploy demo app]"
end

template upstart_config do
  source "upstart/node-web.conf.erb"
  owner "root"
  group "root"
  mode "0600"

  notifies :restart, "service[#{app_name}]"
end

execute "deploy demo app" do
  action :nothing
  command "#{deployer_home}/bin/deploy #{node_user} --skip-update"
  user deploy_user
  group "stackful"
  # npm install is notoriously flakey, so retry up to 6 times
  #retries 6
  #retry_delay 10
  notifies :restart, "service[#{app_name}]"
end

service app_name do
  action :nothing
  provider Chef::Provider::Service::Upstart
end

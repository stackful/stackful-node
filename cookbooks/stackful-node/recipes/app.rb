#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
app_user = settings["user"]
app_group = settings["group"]
app_user_home = "/home/#{app_user}"
app_home = settings["app-home"]
app_name = settings["app-name"]
install_demo_marker = File.join(app_home, "install-demo")
config_file = File.join("/etc", "stackful", "node.json")
demo_repo = settings["demo-repo"]
upstart_config = "/etc/init/#{app_name}.conf"
git_settings = node["stackful-git"]
deploy_user = git_settings["deploy-user"]
deployer_home = git_settings["deployer-home"]
#####################################################################

group app_group
user app_user do
  gid app_group
  home app_user_home
end

directory app_user_home do
  owner app_user
  group app_group
  mode 00755
end

group "stackful" do
  members [app_user]
  append true
end

execute "secure node config" do
  command "chgrp stackful '#{config_file}' && chmod 660 '#{config_file}'"
end

execute "create app home" do
  command <<-EOCOMMAND
mkdir -p '#{app_home}' && \
chown -R #{app_user}:#{app_group} '#{app_home}'
EOCOMMAND

  notifies :run, "execute[demo app install]"
  not_if { ::File.exists?(app_home) }
end

execute "demo app install" do
  action :nothing
  user app_user
  group app_group
  cwd "/tmp"

  command <<-EOCOMMAND
git clone https://github.com/stackful/#{demo_repo}.git '#{app_home}' && \
rm -rf '#{app_home}/.git'
EOCOMMAND
  notifies :run, "execute[deploy demo app]"
end

template upstart_config do
  source "upstart/#{app_name}.conf.erb"
  owner "root"
  group "root"
  mode "0600"

  notifies :restart, "service[#{app_name}]"
end

execute "deploy demo app" do
  action :nothing
  command "#{deployer_home}/bin/deploy #{app_user} --skip-update"
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

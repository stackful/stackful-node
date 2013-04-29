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

execute "install meteor" do
  command "curl https://install.meteor.com | /bin/sh"
  not_if "which meteor"
end

execute "install meteorite" do
  command "npm install meteorite -g"
  not_if "which mrt"
end

execute "create app home" do
  command <<-EOCOMMAND
mkdir -p '#{app_home}' && \
touch '#{install_demo_marker}' && \
chown -R #{node_user}:#{node_group} '#{app_home}'
EOCOMMAND

  not_if { ::File.exists?(app_home) }
end

execute "demo app install" do
  user node_user
  group node_group
  cwd "/tmp"

  command <<-EOCOMMAND
curl -L https://github.com/stackful/#{demo_repo}/archive/master.tar.gz | tar zx && \
mkdir -p #{app_home} && \
rsync -a #{demo_repo}-master/ '#{app_home}' && \
rm -rf #{demo_repo}-master && \
rm '#{install_demo_marker}'
EOCOMMAND
  only_if { ::File.exists?(install_demo_marker) }
end

template upstart_config do
  source "upstart/node-web.conf.erb"
  owner "root"
  group "root"
  mode "0600"
end

execute "deploy demo app" do
  command "#{deployer_home}/bin/deploy #{node_user} --skip-update"
  user deploy_user
  group "stackful"
  # npm install is notoriously flakey, so retry up to 6 times
  #retries 6
  #retry_delay 10
end

execute "stop node-web || true"
execute "start node-web"

#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
app_home = settings["app-home"]
app_name = settings["app-name"]
node_user = settings["user"]
node_group = settings["group"]
mongo_user = settings["db-user"]
mongo_password = settings["db-password"]
upstart_config = "/etc/init/node-web.conf"
config_file = File.join("/etc", "stackful", "node.json")
demo_repo = "demo-node-express-mongodb"
install_demo_marker = File.join(app_home, "install-demo")

#####################################################################

# TODO: properly detect the user in a not_if clause
execute "create_mongodb_user" do
  command <<-EOCOMMAND
mongo localhost/#{app_name} --eval "
  if (db.system.users.find({'user': '#{mongo_user}'}).length() == 0) {
    db.addUser('#{mongo_user}', '#{mongo_password}')
  }
"
EOCOMMAND
end

group node_group
user node_user do
  gid node_group
end

execute "secure node config" do
  command "chgrp #{node_group} '#{config_file}' && chmod 660 '#{config_file}'"
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
mv #{demo_repo}-master/* #{app_home} && \
rm -rf #{demo_repo}-master && \
rm '#{install_demo_marker}'
EOCOMMAND
  only_if { ::File.exists?(install_demo_marker) }
end

cookbook_file "/usr/local/bin/stackful-node-web" do
  source "stackful-node-web"
  mode 00755

  owner "root"
  group "root"
end

template upstart_config do
  source "upstart/node-web.conf.erb"
  owner "root"
  group "root"
  mode "0600"
end

execute "npm install" do
  user node_user
  group node_group
  environment({
    "HOME" => app_home
  })
  cwd app_home
  # npm install is notoriously flakey, so retry up to 6 times
  retries 6
  retry_delay 10
end

execute "stop node-web || true"
execute "start node-web"

apt_repository "nginx" do
  # Ubuntu only!
  uri "http://ppa.launchpad.net/sjinks/x3m/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "67C617E5"
end

include_recipe "nginx::default"

# The nginx::default recipe has the gzip config in the main nginx.conf file,
# so we need this to avoid duplicate config errors.
execute "fix x3m nginx config" do
  command "rm -f '/etc/nginx/conf.d/gzip.conf'"
end

["default", "000-default"].each do |unused_default|
  nginx_site unused_default do
    enable false
  end
end

template "/etc/nginx/sites-available/node-web" do
  source "nginx/node-web.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

nginx_site app_name do
  enable true
end

#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
app_home = settings["app-home"]
app_name = settings["app-name"]
node_user = settings["user"]
node_group = settings["group"]
mongo_user = settings["db-user"]
upstart_config = "/etc/init/node-web.conf"
config_file = File.join("/etc", "stackful", "stackful-node.json")
demo_repo = "demo-node-express-mongodb"
install_demo_marker = File.join(app_home, "install-demo")

::Chef::Recipe.send(:include, ::Opscode::OpenSSL::Password)
generated_mongodb_password = secure_password
::Chef::Recipe.send(:include, ::Stackful::Config)
::Chef::Resource::RubyBlock.send(:include, ::Stackful::Config)
#####################################################################

ruby_block "generate_new_db_password" do
  block do
    node.set_unless["stackful-node"]["db-password"] = generated_mongodb_password
  end
  only_if { mongo_url(config_file).nil? }
end

# don't use execute, as it seems to use attributes set at recipe compile time
# and we fetch the db-password later on
ruby_block "create_mongodb_user" do
  block do
    command = <<EOF
  mongo localhost/#{app_name} --eval "
    if (db.system.users.find({'user': '#{mongo_user}'}).length() == 0) {
      db.addUser('#{mongo_user}', '#{node['stackful-node']['db-password']}')
    }
  "
EOF

    system command
  end
  only_if { mongo_url(config_file).nil? }
end

ruby_block "read_current_db_password" do
  block do
    mongo_url = mongo_url config_file
    m = mongo_url.match(/mongodb:\/\/(?<user>[^:]+):(?<password>[^@]+).*/)
    node.set_unless["stackful-node"]["db-password"] = m["password"]
  end
  not_if { mongo_url(config_file).nil? }
end

group node_group
user node_user do
  gid node_group
end

ruby_block "write stack config" do
  block do
    config = read_config config_file
    config["web"] ||= {}
    config["web"]["environment"] ||= {}
    env = config["web"]["environment"]

    mongo_url = "mongodb://#{mongo_user}:#{node['stackful-node']['db-password']}@localhost/#{app_name}"
    env["MONGO_URL"] = mongo_url

    File.open(config_file, "w") do |cf|
      cf.puts(JSON.pretty_generate(config))
    end
  end
end

execute "secure stack config" do
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

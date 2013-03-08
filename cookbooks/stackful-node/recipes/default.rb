#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
app_home = settings["app-home"]
app_name = settings["app-name"]
node_user = settings["user"]
node_group = settings["group"]
upstart_config = "/etc/init/node-web.conf"

::Chef::Recipe.send(:include, ::Opscode::OpenSSL::Password)
generated_mongodb_password = secure_password
puts "NEW MONGODB PASSWORD: " + generated_mongodb_password
#####################################################################


ruby_block "generate_new_db_password" do
  block do
    node.set_unless["stackful-node"]["db-password"] = generated_mongodb_password
    puts "MONGO PASSWORD: " + node["stackful-node"]["db-password"]
  end
  not_if { ::File.exists?(upstart_config) }
end

ruby_block "read_current_db_password" do
  block do
    upstart_config_text = ::File.read(upstart_config)
    m = upstart_config_text.match(/MONGO_URL=mongodb:\/\/(?<user>[^:]+):(?<password>[^@]+).*/)
    node.set_unless["stackful-node"]["db-password"] = m["password"]
    puts "MONGO PASSWORD: " + node["stackful-node"]["db-password"]
  end
  only_if { ::File.exists?(upstart_config) }
end

group node_group
user node_user do
  gid node_group
end

remote_directory app_home do
  owner node_user
  group node_group
  files_owner node_user
  files_group node_group
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
end

execute "stop node-web || true"
execute "start node-web"

include_recipe 'nginx::default'

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

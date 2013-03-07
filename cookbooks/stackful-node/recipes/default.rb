settings = node["stackful-node"]

app_home = settings["app-home"]
app_name = settings["app-name"]
node_user = settings["user"]
node_group = settings["group"]

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

template "/etc/init/node-web.conf" do
  source "upstart/node-web.conf.erb"
  owner "root"
  group "root"
  mode "0644"
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

#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
app_name = settings["app-name"]
mongo_user = settings["db-user"]
mongo_password = settings["db-password"]
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

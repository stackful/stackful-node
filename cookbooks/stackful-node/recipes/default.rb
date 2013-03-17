#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
app_home = settings["app-home"]
app_name = settings["app-name"]
node_user = settings["user"]
node_group = settings["group"]
mongo_user = settings["db-user"]
deploy_user = settings["deploy-user"]
upstart_config = "/etc/init/node-web.conf"
deploy_repo = "/home/#{deploy_user}/#{app_name}.git"
config_file = File.join("/etc", "stackful", "stackful-node.json")

::Chef::Recipe.send(:include, ::Opscode::OpenSSL::Password)
generated_mongodb_password = secure_password
puts "NEW MONGODB PASSWORD: " + generated_mongodb_password
#####################################################################

if settings["deploy-user"].nil?
  Chef::Application.fatal!("You must set ['stackful-node']['deploy-user'].")
end

ruby_block "generate_new_db_password" do
  block do
    node.set_unless["stackful-node"]["db-password"] = generated_mongodb_password
  end
  not_if { ::File.exists?(upstart_config) }
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
  not_if { ::File.exists?(upstart_config) }
end

ruby_block "read_current_db_password" do
  block do
    upstart_config_text = ::File.read(upstart_config)
    m = upstart_config_text.match(/MONGO_URL=mongodb:\/\/(?<user>[^:]+):(?<password>[^@]+).*/)
    node.set_unless["stackful-node"]["db-password"] = m["password"]
  end
  only_if { ::File.exists?(upstart_config) }
end

group node_group
user node_user do
  gid node_group
end

ruby_block "write stack config" do
  block do
    require 'json'
    config = {}
    begin
      File.open(config_file, "r") do |cf|
        config = JSON.parse(cf.read)
      end
    rescue Errno::ENOENT
    end

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

remote_directory app_home do
  source "node-web"
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

package "git"

execute "mkdir -p #{deploy_repo}" do
  user deploy_user
  group deploy_user

  not_if { File.exists?(deploy_repo) }
end

ruby_block "write git repo summary" do
  block do
    home = ENV["HOME"]
    summary_file = File.join(home, "stackful-node-summary.txt")

    require 'net/http'
    external_ip = Net::HTTP.get(URI.parse('http://icanhazip.com')).strip

    git_url = "#{deploy_user}@#{external_ip}:#{app_name}.git"

    File.open(summary_file, "a+") do |f|
      f.puts <<EOF

Git Configuration
=================

Your deployment repository is available at:

    #{git_url}

Configure it as a remote on your current Git repository with a command like:

    git remote add stackful #{git_url}

And then, when you want to deploy your code to the server, just push to the master branch:

    git push stackful master


HTTP Configuration
==================

Your web server is listening and has a demo web app configured at:

    http://#{external_ip}

The application will be automatically restarted on every push deployment and your changes will immediately go live.
EOF
    end
  end
  not_if { File.exists?("#{deploy_repo}/refs") }
end

execute "git init --bare" do
  user deploy_user
  group deploy_user
  cwd deploy_repo

  not_if { File.exists?("#{deploy_repo}/refs") }
end

remote_directory deploy_repo do
  source "deploy-repo"
  owner deploy_user
  group deploy_user
  files_owner deploy_user
  files_group deploy_user
end

template "#{deploy_repo}/hooks/post-update" do
  source "deploy-repo/hooks/post-update.erb"
  owner deploy_user
  group deploy_user
  mode "0744"
end


template "/etc/sudoers.d/#{deploy_user}" do
  source "deploy-sudo.erb"
  owner "root"
  group "root"
  mode "0440"
end

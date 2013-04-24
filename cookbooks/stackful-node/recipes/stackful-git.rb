#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
git_settings = node["stackful-git"]
deploy_user = git_settings["deploy-user"]
deploy_key = git_settings["deploy-key"]
deployer_source = git_settings["deployer-source"]
deployer_home = git_settings["deployer-home"]
deployer_branch = git_settings["deployer-branch"]
app_name = settings["app-name"]
deploy_user_home = "/home/#{deploy_user}"
deploy_repo = "#{deploy_user_home}/#{app_name}.git"
#####################################################################

if git_settings["deploy-user"].nil?
  Chef::Application.fatal!("You must set ['stackful-git']['deploy-user'].")
end

package "git"

group deploy_user
user deploy_user do
  gid deploy_user
  home deploy_user_home
end

group "stackful" do
  members [deploy_user]
  append true
end

directory deploy_user_home do
  owner deploy_user
  group deploy_user
  mode 00755
end

execute "deploy user authorized_keys" do
  user deploy_user
  group deploy_user
  cwd deploy_user_home

  command <<-EOCOMMAND
mkdir -p .ssh && \
chmod 700 .ssh && \
echo "#{deploy_key.strip}" > .ssh/authorized_keys && \
chmod 600 .ssh/authorized_keys
EOCOMMAND
  not_if { ::File.exists?("#{deploy_user_home}/.ssh/authorized_keys") }
end

execute "mkdir -p #{deploy_repo}" do
  user deploy_user
  group deploy_user

  not_if { File.exists?(deploy_repo) }
end

execute "git init --bare" do
  user deploy_user
  group deploy_user
  cwd deploy_repo

  not_if { File.exists?("#{deploy_repo}/refs") }
end

execute "install app-deployer" do
  command <<-EOCOMMAND
mkdir -p '#{deployer_home}' && \
cd '#{deployer_home}' && \
git init && \
git remote add origin '#{deployer_source}'
EOCOMMAND
  not_if { ::File.exists?("#{deployer_home}/.git") }
end

execute "update app-deployer" do
  cwd deployer_home
  command <<-EOCOMMAND
git fetch -f origin #{deployer_branch} && \
git reset --hard FETCH_HEAD
EOCOMMAND
end

template "#{deploy_repo}/hooks/post-update" do
  source "repository/hooks/post-update.erb"
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

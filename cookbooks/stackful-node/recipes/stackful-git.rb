#####################################################################
# Settings
#####################################################################
settings = node["stackful-node"]
git_settings = node["stackful-git"]
deploy_user = git_settings["deploy-user"]
app_name = settings["app-name"]
deploy_repo = "/home/#{deploy_user}/#{app_name}.git"
#####################################################################

if git_settings["deploy-user"].nil?
  Chef::Application.fatal!("You must set ['stackful-git']['deploy-user'].")
end

package "git"

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

remote_directory deploy_repo do
  source "repository"
  owner deploy_user
  group deploy_user
  files_owner deploy_user
  files_group deploy_user
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

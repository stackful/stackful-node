execute "install meteor" do
  command "curl https://install.meteor.com | /bin/sh"
  not_if "which meteor"
end

execute "install meteorite" do
  command "npm install meteorite -g"
  not_if "which mrt"
end

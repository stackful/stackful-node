execute "install meteorite" do
  command "npm install meteorite -g"
  not_if "which mrt"
end

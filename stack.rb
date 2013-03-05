root = File.absolute_path(File.dirname(__FILE__))

file_cache_path root
role_path "#{root}/roles"
cookbook_path ["#{root}/cookbooks", "#{root}/imported-cookbooks"]

require 'json'

module Stackful
  module Config
    def read_config(config_file)
      config = {}
      begin
        File.open(config_file, "r") do |cf|
          config = JSON.parse(cf.read)
        end
      rescue Errno::ENOENT
      end
      config
    end

    def mongo_url(config_file)
      config = read_config config_file
      web = config["web"] || {}
      env = web["environment"] || {}
      env["MONGO_URL"]
    end
  end
end

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
  end
end

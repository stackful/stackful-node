name             "stackful-node"
maintainer       "Hristo Deshev"
maintainer_email "hristo@stackful.io"
license          "Apache 2.0"
description      "Installs/Configures the Stackful.io Node.js stack"
long_description IO.read(File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'README.md'))
version          "1.0.0"

recipe "stackful-node", "The Stackful.io Node.js web app stack"

%w{ apt build-essential openssl ohai nginx mongodb nodejs }.each do |os|
  depends os
end

%w{ ubuntu }.each do |os|
  supports os
end

attribute "stackful-node/app-home",
  :display_name => "Node.js application deploy dir",
  :description => "The location that hosts the application files.",
  :default => "/var/www/node-web"

name 'nodejs-webserver'
description 'Stackful.io Node.js web app server'
#override_attributes({ "apache" => {
                                      #"proxypass" => [" /  http://localhost:8080/"]
                                  #}
                   #})

default_attributes(
    "nodejs" => {
    "install_method" => "source",
    "version" => "0.10.0"
  },
    "nginx" => {
    "install_method" => "package",
    "version" => "1.3.14"
  },
    "mongodb" => {
    "bind_ip" => "127.0.0.1"
  }
)


run_list [
  "recipe[nginx::default]",
  "recipe[nodejs::default]",
  "recipe[mongodb::10gen_repo]",
  "recipe[mongodb::default]",
  'recipe[stackful-node::default]'
]

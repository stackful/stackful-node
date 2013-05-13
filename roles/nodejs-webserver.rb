name 'nodejs-webserver'
description 'Stackful.io Node.js web app server'
#override_attributes({ "apache" => {
                                      #"proxypass" => [" /  http://localhost:8080/"]
                                  #}
                   #})

default_attributes(
    "nodejs" => {
    "install_method" => "package",
    "version" => "0.10.3"
  },
    "nginx" => {
    "install_method" => "package",
    "init_style" => "init",
    "version" => "1.3.14"
  },
    "mongodb" => {
    "bind_ip" => "127.0.0.1"
  }
)


run_list [
  "recipe[nodejs::default]",
  "recipe[mongodb::10gen_repo]",
  "recipe[mongodb::default]",
  'recipe[stackful-node::stackful-git]',
  'recipe[stackful-node::meteorite]',
  'recipe[stackful-node::app]',
  'recipe[stackful-node::default]'
]

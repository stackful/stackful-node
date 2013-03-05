name 'nodejs-webserver'
description 'Stackful.io Node.js web app server'
#override_attributes({ "apache" => {
                                      #"proxypass" => [" /  http://localhost:8080/"]
                                  #}
                   #})

default_attributes(
    "nodejs" => {
    "install_method" => "package",
    "version" => "0.8.21"
  },
    "nginx" => {
    "install_method" => "package",
  }
)


run_list [
  "recipe[nginx::default]",
  "recipe[nodejs::default]",
  "recipe[mongodb::10gen_repo]",
  "recipe[mongodb::default]",

  #'recipe[stackful-node::default]'
]

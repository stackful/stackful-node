# The Stackful.io Node.js Web Stack.

This project hosts the [Stackful.io](http://stackful.io) Node.js stack. We are trying to build a solid Node.js PaaS-like environment using proven infrastructure components and industry best practices. The stack offers a full Node.js web development environment supported by automatic Git push deployments. All that running on your VPS without sacrificing any advanced customizability you need to do.

## Stack Components

* [Nginx](http://nginx.org/) web reverse proxy to automatically serve your static assets and transparently handle heavy-duty stuff like gzip compression or SSL support. We are using a recent release with full WebSocket support.
* [Node.js](http://nodejs.org/), of course. The latest and greatest release.
* [MongoDB](http://www.mongodb.org/) - everyone's favorite NoSQL data store.
* Git deployment. Manual file copying and server restarts isn't too bad, but it isn't fun either. What could be easier than just pushing to a Git repository and have your changes automatically go live?

## Quickstart


To get the ball rolling, log in to your server as root and run the bootstrap script:

    root@test1:~# curl -L install.stackful.io/node | python

The line above downloads a small script that installs the required packages and then gets the rest of the installer and runs it.

Soon after the full installer gets downloaded and started, you will be asked to configure Git deployment. You need to pick a user, set a password, and configure a public key that will be used for passwordless authentication.

![Git user prompt](http://i.imgur.com/5kLUR9H.png)

The SSH public key part is the most important one, so make sure you provide the correct key.

![Git public key prompt](http://i.imgur.com/VAby5QR.png)

Of course, with you having full access to your server, you can always edit your Git deployment user's `~/.ssh/authorized_keys` file and change or add keys that can deploy to your server.

With your Git deployment details now properly set up, the only thing left is to sit back and relax while the installer runs the needed [Chef](http://www.opscode.com/chef/) recipes and updates your server. When it's done, you should see a summary of its progress:

    Finishing stack installation...

    Git Configuration
    =================

    Your deployment repository is available at:

        git@X.X.X.X:node-web.git

    Configure it as a remote on your current Git repository with a command like:

        git remote add stackful git@X.X.X.X:node-web.git

    And then, when you want to deploy your code to the server, just push to the master branch:

        git push stackful master


    HTTP Configuration
    ==================

    Your web server is listening and has a demo web app configured at:

        http://X.X.X.X

    The application will be automatically restarted on every push deployment and your
    changes will immediately go live.

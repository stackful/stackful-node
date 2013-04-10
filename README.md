# The Stackful.io Node.js Web Stack.

This project hosts the [Stackful.io](http://stackful.io) Node.js stack. We are building a solid Node.js PaaS environment using proven infrastructure components and industry best practices. The stack offers a full Node.js web development environment supported by automatic Git push deployments. All that running on your server without sacrificing any advanced customizability you need to do.

## Stack Components

* [Nginx](http://nginx.org/) web reverse proxy to automatically serve your static assets and transparently handle heavy-duty stuff like gzip compression or SSL support. We are using a recent release with full WebSocket support.
* [Node.js](http://nodejs.org/), of course. The latest and greatest release.
* [MongoDB](http://www.mongodb.org/) - everyone's favorite NoSQL data store.
* Git deployment. Manual file copying and server restarts isn't too bad, but it isn't fun either. What could be easier than just pushing to a Git repository and have your changes automatically go live?

## Quickstart


To get the ball rolling, launch a server and pick the Node.js stack. We ask for your Git SSH public key, so that you can do Git deployments later on.

With your Git deployment details now properly set up, the only thing left is to sit back and relax while the installer runs the needed [Chef](http://www.opscode.com/chef/) recipes and updates your server. Watch your dashboard for updates. When the stack installation is done, you should see all the settings you need on the server details screen.


## Git Configuration

Your deployment repository is available at:

    git@X.X.X.X:node-web.git

Where X.X.X.X is really your server's IP address.

Configure the deployment repository as a remote on your local development Git repository with a command like:

    git remote add stackful git@X.X.X.X:node-web.git

And then, when you want to deploy your code to the server, just push to the master branch:

    git push stackful master


## HTTP Configuration

Your web server is listening and has a demo web app configured at:

    http://X.X.X.X

The application will be automatically restarted on every push deployment and your
changes will immediately go live.

## Deploying Your Application to Your Server

The summary above says it all, but let's go through the process together. First you need to add your server's deploy repository as a remote:

    ~/tmp/test-deploy $ git remote add stackful git@X.X.X.X:node-web.git

Then push your current branch:

    ~/tmp/test-deploy $ git push stackful master                                                       [master]
    Counting objects: 44, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (35/35), done.
    Writing objects: 100% (44/44), 3.74 KiB, done.
    Total 44 (delta 17), reused 0 (delta 0)
    remote: Initialized empty Git repository in /var/www/node-web/.git/
    remote: From /home/git/node-web
    remote:  * branch            master     -> FETCH_HEAD
    remote: HEAD is now at fcbd3ce deploy.
    remote: npm http GET https://registry.npmjs.org/express/3.0.6
    ...
    remote: npm http 200 https://registry.npmjs.org/formidable/-/formidable-1.0.11.tgz
    remote: 
    remote: ejs@0.8.3 node_modules/ejs
    remote: 
    remote: express@3.0.6 node_modules/express
    remote: ├── methods@0.0.1
    remote: ├── fresh@0.1.0
    remote: ├── range-parser@0.0.4
    remote: ├── cookie-signature@0.0.1
    remote: ├── buffer-crc32@0.1.1
    remote: ├── cookie@0.0.5
    remote: ├── debug@0.7.2
    remote: ├── commander@0.6.1
    remote: ├── mkdirp@0.3.3
    remote: ├── send@0.1.0 (mime@1.2.6)
    remote: └── connect@2.7.2 (pause@0.0.1, bytes@0.1.0, formidable@1.0.11, qs@0.5.1)
    remote: node-web start/running, process 2109
    remote: Setting up a mirror Git repository at '/var/www/node-web'.
    remote: Wiping demo web app in '/var/www/node-web'...
    remote: Restarting: node-web ...
    To git@X.X.X.X:node-web.git
     * [new branch]      master -> master


As you can see your code got deployed to `/var/www/node-web` (the default location). The deployer nuked the existing demo app and ran `npm` to update your required packages listed in your `package.json` file. `npm` updates get triggered on every deployment, so that dependencies are kept in sync with your configuration. Refresh your browser and you should see your changes live.

## Database Credentials and Other Configuration Settings

The Node.js stack will provide configuration settings to your app via standard environment variables. That is how, for example, you can get your MongoDB connection settings. In your app.js starter script, read the `MONGO_URL` environment variable:

    #!javascript
    var mongo_url = process.env.MONGO_URL || "mongodb://localhost/todos"

Note how we fall back to a predefined value, if the environment variable is not configured. This is convenient when testing on your local workstation.

You can use the same technique to get your application port:


    #!javascript
    app.configure(function(){
    app.set('port', process.env.PORT || 3000);
    ...
    });


## Manual Deployment (sans Git)

Git is a very cool source control system, but it's still far from global domination. If you use another SCM tool or just don't like Git push deployments, you can deploy manually using a directory copy and restart command combo. Here is one that uses `rsync` to transfer your app's files to the remote server and then tells Upstart to restart the Node.js app:

    ~/tmp/test-deploy $ rsync -avz --delete ./ git@X.X.X.X:/var/www/node-web
    sending incremental file list
    ./
    app.js

    sent 16268 bytes  received 177 bytes  10963.33 bytes/sec
    total size is 1376738  speedup is 83.72
    ~/tmp/test-deploy $ ssh git@X.X.X.X sudo restart node-web
    node-web start/running, process 2586


Note that you will need to change the `/var/www/node-web` directory ownership or permissions, so that your `deploy` user has write permissions. Your deployment user needs to have sudo privileges in order to restart Upstart jobs as root.

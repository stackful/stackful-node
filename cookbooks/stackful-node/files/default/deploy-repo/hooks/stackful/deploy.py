from __future__ import absolute_import, division, print_function, unicode_literals

import sys, os, errno
import subprocess


class GitDeploy(object):
    def __init__(self, app_user, app_name, source_repo, app_dir):
        self.app_user = app_user
        self.app_name = app_name
        self.source_repo = source_repo
        self.app_dir = app_dir

    def ensure_repo(self):
        if not os.path.exists(self.app_dir):
            mkdir_p(self.app_dir)
            sudo("chown {} '{}'".format(self.app_user, self.app_dir))

        git_dir = os.path.join(self.app_dir, ".git")
        if not os.path.exists(git_dir):
            print("Setting up a mirror Git repository at '{}'.".format(self.app_dir))
            if os.path.exists(os.path.join(self.app_dir, "stackful-demo.txt")):
                print("Wiping demo web app in '{}'...".format(self.app_dir))
                self.app_run("rm -rf * .* || true")

            self.app_run("git init")
            self.app_run("git remote add origin '{}'".format(self.source_repo))

    def pull_latest(self):
        self.app_run("git fetch -f origin master")
        self.app_run("git reset --hard FETCH_HEAD")

    def update_npm(self):
        # Pass the HOME folder so that npm writes its .npm dir somewhere it can
        # Ignore errors
        self.app_run("HOME='{}' npm install || true".format(self.app_dir))

    def restart(self):
        print("Restarting: {} ...".format(self.app_name))
        # Restart our Upstart job
        sudo("restart {}".format(self.app_name))

    def app_run(self, cmd):
        sudo("cd '{}' && {}".format(self.app_dir, cmd), self.app_user)

    def deploy(self):
        self.ensure_repo()
        self.pull_latest()
        self.update_npm()
        self.restart()


def run(cmd):
    subprocess.check_call(cmd, shell=True)


def sudo(cmd, user="root"):
    escaped_quotes = cmd.replace('"', '\\"')
    sudo_cmd = "sudo -u {} sh -c \"{}\"".format(user, escaped_quotes)
    run(sudo_cmd)


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


if __name__ == "__main__":
    if len(sys.argv) != 1 + 4:
        print("deploy.py <app user> <app name> <source repo> <app_dir>")
        sys.exit(0)

    app_user, app_name, source_repo, app_dir = sys.argv[1:]
    deployer = GitDeploy(app_user, app_name, source_repo, app_dir)
    deployer.deploy()

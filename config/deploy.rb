require 'json'

# config valid only for current version of Capistrano
lock "3.9.1"

set :application, "crowdfunding"
set :repo_url, "git@gitlab.com:200ok/crowdfunding.git"
set :ssh_options, { forward_agent: true }
set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.4.1'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/app/app"


# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/secrets.yml", "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :rails_env, 'production'

namespace :deploy do

  task :mattermost_started do
    mattermost "#{fetch(:me)} STARTED a deployment of "+
          "#{fetch(:application)} (#{fetch(:branch)}) to #{fetch(:stage)}"
  end
  after :started, :mattermost_started


  task :mattermost_finished do
    mattermost "#{fetch(:me)} FINISHED a deployment of "+
          "#{fetch(:application)} (#{fetch(:branch)}) to #{fetch(:stage)}"
  end
  after :finished, :mattermost_finished


  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "RAILS_ENV=#{fetch(:rails_env)} $HOME/bin/unicorn_wrapper restart"
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

def mattermost(message)
  url = "https://brandnewchat.ungleich.ch/hooks/q568tnt5jtywtftoz3ghfgicyw"
  payload = {
    text: message,
  }
  json = JSON.unparse(payload)
  cmd = "curl -X POST --data-urlencode 'payload=#{json}' '#{url}' 2>&1"
  %x[ #{cmd} ]
end
require 'bundler/capistrano'
require 'capistrano/ext/multistage'

set :application, "static"

set :stages, %w(staging)
set :default_stage, 'staging'

set :scm, :git

namespace :deploy do
  desc 'Link airbrake config'
  task :link_airbrake_conf, roles: :app do
    run "ln -nfs #{shared_path}/config/airbrake.rb \
                 #{release_path}/config/initializers/airbrake.rb"
  end
end

after 'deploy:update_code', 'deploy:link_airbrake_conf'
after 'deploy',             'deploy:cleanup'

load 'deploy/assets'

set :assets_prefix, 'static'

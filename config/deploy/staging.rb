set :rails_env, :staging

set :default_environment, {
  'PATH' => '/opt/ruby193/bin:$PATH', # use ruby 1.9.3
  'RAILS_ENV' => rails_env,
}

set :branch, 'bis'
set :domain_name, 'static.apps.bitzesty.com'

server 'static.apps.bitzesty.com', :app, :web, primary: true

set :user, 'bitzesty'
set :repository,  'git@github.com:bitzesty/static.git'
set :branch, 'bis'
set :use_sudo, false
set :ssh_options, { keys: ['certs/bitzesty.pem'], forward_agent: true }

set :deploy_to, "/home/#{user}/www/#{application}"
set :deploy_via, :remote_cache

set :unicorn_pid, "#{shared_path}/pids/unicorn.pid"
set :nginx_site_conf, "/etc/nginx/sites-enabled/#{application}.#{rails_env}.conf"

namespace :deploy do
  desc 'Restart the app'
  task :restart, roles: :app do
    if 'true' == capture("if [ -e #{unicorn_pid} ]; then echo 'true'; fi").strip
      stop
    end

    start
  end

  desc 'Stop unicorns'
  task :stop, roles: :app do
    run "cat #{unicorn_pid} | xargs kill -QUIT"
  end

  desc 'Start unicorns'
  task :start, roles: :app do
    run "cd #{current_path} && \
         bundle exec unicorn \
          -c #{current_path}/config/unicorn.conf.rb \
          --env #{rails_env} \
          --daemonize"
  end

  desc 'Make shared_path/config'
  task :mkdir_config, roles: :app do
    run "mkdir -p #{shared_path}/config"
  end

  desc "Generate unicorn and nginx's config files"
  task :server_config, roles: :app do
    unicorn_tmpl = ERB.new File.read("config/deploy/unicorn.conf.rb.erb")
    nginx_tmpl   = ERB.new File.read("config/deploy/nginx.app.conf.erb")

    run "mkdir -p #{shared_path}/config"

    put unicorn_tmpl.result(binding), "#{shared_path}/config/unicorn.conf.rb"
    put nginx_tmpl.result(binding),   "#{shared_path}/config/nginx.app.conf"
  end

  desc 'Link unicorn config'
  task :link_unicorn_conf, roles: :app do
    run "ln -nfs #{shared_path}/config/unicorn.conf.rb \
                 #{release_path}/config/unicorn.conf.rb"
  end

  desc 'Link airbrake config'
  task :link_airbrake_conf, roles: :app do
    run "ln -nfs #{shared_path}/config/airbrake.rb \
                 #{release_path}/config/initializers/airbrake.rb"
  end


  desc "Nginx deploy introduction"
  task :nginx, roles: :app do
    puts <<-INTRODUCTION
      Contact our system admin running the following commands in order to deploy/undeploy
      the current application.

      Deploy:
        sudo ln -nfs #{shared_path}/config/nginx.app.conf #{nginx_site_conf} && cat /var/run/nginx.pid | xargs sudo kill -HUP

      Undeploy:
        sudo rm #{nginx_site_conf} && cat /var/run/nginx.pid | xargs sudo kill -HUP
    INTRODUCTION
  end
end

after 'deploy:setup',       'deploy:mkdir_config'

after 'deploy:update_code', 'deploy:link_unicorn_conf'
after 'deploy:update_code', 'deploy:link_airbrake_conf'

after 'deploy',             'deploy:cleanup'

load 'deploy/assets'

set :assets_prefix, 'static'

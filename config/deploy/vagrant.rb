server '10.0.100.11', :app, :web, primary: true

ssh_options[:forward_agent] = true
default_run_options[:pty] = true

set :default_environment, {
  'LANG' => 'en_US.UTF-8',
  'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

set :bundle_flags, "--deployment --quiet --binstubs --shebang ruby-local-exec"

set :application, 'static'
set :user, 'bis'
set :deploy_to, "/home/bis/#{application}"
set :rails_env, 'vagrant'
set :branch, 'bis'
set :use_sudo, false
set :deploy_via, :remote_cache

set :repository,  'git@github.com:bitzesty/static.git'
set :scm, :git

namespace :deploy do
  task :export, except: { no_release: true } do
    run "cd #{current_path} && bundle exec foreman export upstart /home/#{user}/.init -a #{application} -f Procfile -u #{user} -l #{shared_path}/log -t config/deploy/templates"
  end

  task :start, except: { no_release: true } do
    run "start #{application}"
  end

  task :stop, except: { no_release: true } do
    run "stop #{application}"
  end

  task :restart, except: { no_release: true } do
    run "start #{application} || restart #{application}"
  end
end

namespace :unicorn do
  desc "Generate unicorn and nginx's config files"
  task :config do
    unicorn_tmpl = ERB.new File.read("config/deploy/unicorn.conf.rb.erb")

    run "mkdir -p #{shared_path}/config"

    put unicorn_tmpl.result(binding), "#{shared_path}/config/unicorn.conf.rb"

    run "ln -nfs #{shared_path}/config/unicorn.conf.rb \
                 #{release_path}/config/unicorn.conf.rb"
  end
end

before 'deploy:restart', 'deploy:export'
after 'deploy:update_code', 'unicorn:config'

load 'dotenv/capistrano'

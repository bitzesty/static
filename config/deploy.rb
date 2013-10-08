require 'bundler/capistrano'
require 'capistrano/ext/multistage'

set :application, "static"

set :stages, %w(staging)
set :default_stage, 'staging'

set :scm, :git

require 'sinatra'
require 'securerandom'
require 'sequel'
require 'digest'
require 'rack'
require 'yaml'
require 'json'
require_relative 'src/main'

# Process::UID.change_privilege(48) if Process.uid == 0

ERRORS = YAML.load(File.open('errors.yml'))

class App < Sinatra::Application
  # use Rack::Session::Pool, expire_after: 600
  # use Rack::Protection::RemoteToken
  # use Rack::Protection::SessionHijacking\

  configure do
    enable :logging
    enable :protection
    # enable :sessions
    # set :logging, 'logs'
    set :environment, :development
    set :server, :puma
    set :threaded, true
    set :bind, '0.0.0.0'
    set :port, 9292
    set :show_exceptions, :after_handler
    set :public_folder, __dir__ + '/static'
    set :static_cache_control, [:public, { max_age: 300 }]
    # set :session_store, Rack::Session::Pool
  end

  not_found do
    status 200
    # File.open('static/index.html').read
    status 404
    content_type :json
    {
      :code => 404,
      :reason => 'This is nowhere to be found.'
    }.to_json
  end

  use Base
  use Function
  
  get '/' do
    # headers["Access-Control-Allow-Origin"] = "*"
    # File.open('static/index.html').read
    # redirect ""
    erb :index
  end
end
  
disable :run
App.run! if $PROGRAM_NAME == App.app_file
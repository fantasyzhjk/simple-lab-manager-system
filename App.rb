require 'sinatra'
require 'sinatra/cors'
require 'securerandom'
require 'sequel'
require 'digest'
require 'rack'
require 'yaml'
require 'json'
require_relative 'src/main'

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
    set :port, 8080
    set :show_exceptions, :after_handler
    set :public_folder, __dir__ + '/static'
    set :static_cache_control, [:public, { max_age: 300 }]
    # set :session_store, Rack::Session::Pool
  end

  register Sinatra::Cors

  set :allow_origin, "http://localhost:8080/"
  set :allow_methods, "GET,HEAD,POST"
  set :allow_headers, "content-type,if-modified-since"
  set :expose_headers, "location,link"

  get '/' do
    # headers["Access-Control-Allow-Origin"] = "*"
    erb :index
  end
  use Base
  use Function
end
  
disable :run
App.run! if $PROGRAM_NAME == App.app_file
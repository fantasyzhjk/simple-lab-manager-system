require_relative 'base'
require_relative 'objects'
require_relative 'utils'
require_relative 'database'

$users = []
# Process::UID.change_privilege(48) if Process.uid == 0
class Function < Sinatra::Base
  helpers do
    def json_status(code, message)
      status code if code < 1000
      {
        :code => code,
        :message => message
      }.to_json
    end

    def json_data(code, data, message = "Success")
      {
        :code => code,
        :message => message,
        :data => data
      }.to_json
    end
  
    def accept_params(params, *fields)
      h = { }
      fields.each do |name|
        h[name] = params[name] if params[name]
      end
      h
    end

    def accept_json_params(body, *fields)
      params = JSON.load(body)
      h = { }
      fields.each do |name|
        h[name] = params[name.to_s] if params[name.to_s]
      end
      h
    end
  end

  post '/login', :provides => :json do
    content_type :json
    newParams = accept_json_params(request.body, :id, :password)
    data = DataBase.new.getUser(newParams[:id])
    if newParams[:password] == data[:password]
      userInfo = UserAuth.new(userId: data[:id], userName: data[:name], token: SecureRandom.hex(32))
      $users << userInfo
      status 200
      tmp = userInfo.to_hash
      tmp[:authorizationMethod] = 'Bearer Token'
      json_data 0, tmp
    else
      status 401
      json_status 1001, ERRORS[1001]
    end
  end

  before '/api/*' do
    halt 400 if request.env['HTTP_AUTHORIZATION'] == nil
    avalable = false
    $users.each do |user|
      if user.avalable?
        avalable = true if "Bearer #{user.token}" == request.env['HTTP_AUTHORIZATION']
      else
        $users.delete(user)
        halt(401, json_status(1002, ERRORS[1002])) if "Bearer #{user.token}" == request.env['HTTP_AUTHORIZATION']
      end
    end
    halt 401 if !avalable
  end

  get '/api/get_user_logs' do
    content_type :json
    newParams = accept_params(params, :id)
    id = newParams[:id]
    halt 400 if id.nil?
    data = DataBase.new.getLogs(id.to_i)
    if !(data == [])
      data = data.map do |item|
        item[:time] = Time.at(item[:time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    else
      status 200
      json_data 1003, data, ERRORS[1003]
    end
  end

  get '/api/get_model' do
    content_type :json
    newParams = accept_params(params, :id)
    id = newParams[:id]
    halt 400 if id.nil?
    data = DataBase.new.getModel(id)
    if !data.nil?
      status 200
      json_data 0, data
    else
      status 200
      json_data 1003, data, ERRORS[1003]
    end
  end

  get '/api/get_model_list' do
    content_type :json
    data = DataBase.new.getModelList()
    if !(data == [])
      status 200
      json_data 0, data
    else
      status 200
      json_data 1003, data, ERRORS[1003]
    end
  end

  get '/api/get_repo_info' do
    content_type :json
    newParams = accept_params(params, :id)
    id = newParams[:id]
    halt 400 if id.nil?
    data = DataBase.new.getRepoInfo(id)
    if !data.nil?
      status 200
      json_data 0, data
    else
      status 200
      json_data 1003, data, ERRORS[1003]
    end
  end

  get '/api/get_repo_list' do
    content_type :json
    data = DataBase.new.getRepoList()
    if !(data == [])
      status 200
      json_data 0, data
    else
      status 200
      json_data 1003, data, ERRORS[1003]
    end
  end
end


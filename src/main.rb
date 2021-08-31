require_relative 'base'
require_relative 'objects'
require_relative 'utils'
require_relative 'database'

$users = []
class Function < Sinatra::Base
  helpers do
    def json_message(code, message = "Success")
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
        if params[name.to_s]
          h[name] = params[name.to_s]
        else
          halt 400
        end
      end
      h
    end
  end

  # before do
  #   headers 'Access-Control-Allow-Origin' => '*',
  #   'Access-Control-Allow-Credentials' => 'true',
  #   'Access-Control-Allow-Methods' => ["POST", "GET", "PUT", "OPTIONS", "DELETE"],
  #   'Access-Control-Max-Age' => '3600',
  #   'Access-Control-Allow-Headers' => '*'
  #   halt 200 if request.request_method == 'OPTIONS'
  # end

  post '/login', :provides => :json do
    content_type :json
    newParams = accept_json_params(request.body, :id, :password)
    data = DataBase.new.getUser(newParams[:id])
    if data.nil?
      halt 200, (json_message 1001, ERRORS[1001])
    end
    if newParams[:password] == data[:password]
      userInfo = UserAuth.new(userId: data[:id], userName: data[:name], token: SecureRandom.hex(64))
      $users << userInfo
      status 200
      tmp = userInfo.to_hash
      tmp[:authorizationMethod] = 'Bearer Token'
      json_data 0, tmp
    else
      halt 200, (json_message 1001, ERRORS[1001])
    end
  end

  before '/api/*' do
    halt 400 if request.env['HTTP_AUTHORIZATION'] == nil
    userInfo = nil
    avalable = false
    $users.each do |user|
      if user.avalable?
        if "Bearer #{user.token}" == request.env['HTTP_AUTHORIZATION']
          avalable = true
          userInfo = user
        end
      else
        $users.delete(user)
        halt(401, json_message(1002, ERRORS[1002])) if "Bearer #{user.token}" == request.env['HTTP_AUTHORIZATION']
      end
    end
    halt 401 if !avalable

    settings.get '/api/get_user_logs' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getLogs(id.to_i)
      data = data.map do |item|
        item[:time] = Time.at(item[:time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end

    settings.get '/api/get_logs_all' do
      content_type :json
      db = DataBase.new
      data = db.getLogsAll()
      users = db.getUsers()
      data = data.map do |item|
        item[:time] = Time.at(item[:time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:name] = users[item[:user_id].to_i]
        item 
      end
      status 200
      json_data 0, data
    end

    settings.get '/api/get_log_count' do
      content_type :json
      data = DataBase.new.getLogsCount()
      status 200
      json_data 0, data
    end

    settings.get '/api/get_user_logs_by_limit' do
      content_type :json
      newParams = accept_params(params, :offset, :limit)
      offset = newParams[:offset].to_i
      halt 400 if offset < 0
      limit = newParams[:limit].to_i
      halt 400 if limit < 1
      data = DataBase.new.getLogsBylimit(offset, limit)
      data = data.map do |item|
        item[:time] = Time.at(item[:time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end
  
    settings.get '/api/get_model' do
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
  
    settings.get '/api/get_model_list' do
      content_type :json
      data = DataBase.new.getModelList()
      status 200
      json_data 0, data
    end

    settings.post '/api/add_model', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :name, :type, :description)
      db = DataBase.new
      lines = db.addModel(newParams[:name].to_s, newParams[:type].to_s, newParams[:description].to_s)
      if lines > 0
        db.addLog(userInfo.userId, '新建机器类型', "新建机器类型 #{newParams[:name].to_s}(#{lines})")
        status 200
        json_data 0, {id: lines}
      else
        400
      end
    end

    settings.post '/api/edit_model', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :id, :name, :type, :description)
      db = DataBase.new
      lines = db.editModel(newParams[:id].to_i, newParams[:name].to_s, newParams[:type].to_s, newParams[:description].to_s)
      if lines > 0
        db.addLog(userInfo.userId, '修改机器类型', "修改机器类型 #{newParams[:name].to_s}(#{lines})")
        status 200
        json_message 0
      else
        400
      end
    end

    settings.post '/api/create_repo', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :name, :admin)
      db = DataBase.new
      lines = db.addRepo(newParams[:name].to_s, newParams[:admin].to_s)
      if lines > 0
        db.addLog(userInfo.userId, '新建仓库', "新建仓库 #{newParams[:name].to_s}(#{lines})， 管理员: #{newParams[:admin].to_s}")
        status 200
        json_data 0, {id: lines}
      else
        400
      end
    end

    settings.post '/api/edit_repo', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :id, :name, :admin)
      db = DataBase.new
      lines = db.editRepo(newParams[:id].to_i, newParams[:name].to_s, newParams[:admin].to_s)
      if lines > 0
        db.addLog(userInfo.userId, '修改仓库', "修改仓库 #{newParams[:name].to_s}(#{lines})， 管理员: #{newParams[:admin].to_s}")
        status 200
        json_message 0
      else
        400
      end
    end

    settings.post '/api/delete_repo', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :id)
      db = DataBase.new
      c = db.getRepoInfo(newParams[:id].to_i)
      data = db.getConsumablesByRepo(newParams[:id].to_i)
      halt 200, json_message(1004, ERRORS[1004]) if data != []
      lines = db.deleteRepo(newParams[:id].to_i)
      if lines > 0
        db.addLog(userInfo.userId, '删除仓库', "删除了仓库 #{c[:name]}(#{lines})， 管理员: #{c[:admin]}")
        status 200
        json_message 0
      else
        status 200
        json_message 1003, ERRORS[1003]
      end
    end
  
    settings.get '/api/get_repo_info' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getRepoInfo(id)
      if !data.nil?
        data[:change_time] = Time.at(data[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        data[:add_time] = Time.at(data[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        status 200
        json_data 0, data
      else
        status 200
        json_data 1003, data, ERRORS[1003]
      end
    end
  
    settings.get '/api/get_repo_list' do
      content_type :json
      data = DataBase.new.getRepoList()
      status 200
      json_data 0, data
    end

    settings.get '/api/get_repo_list_all' do
      content_type :json
      data = DataBase.new.getRepoListAll()
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end

    settings.post '/api/create_consumables', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :name, :count, :description, :repo_id, :user_id)
      db = DataBase.new
      ui = db.getUser(newParams[:user_id].to_i)
      halt 400 if ui.nil?
      lines = db.addConsumables(newParams[:name].to_s, newParams[:count].to_i, newParams[:description].to_s, newParams[:repo_id].to_i, newParams[:user_id].to_i)
      if lines > 0
        db.addLog(newParams[:user_id].to_i, '新建耗材', "添加了 #{newParams[:count].to_i} 个 #{newParams[:name].to_s}(#{lines})")
        status 200
        json_data 0, {id: lines}
      else
        400
      end
    end

    settings.post '/api/edit_consumables', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :item_id, :name, :count, :description, :repo_id, :user_id)
      newParams.each {|i| halt 400 if i == ""}  #判断不为空
      halt 400 if newParams[:count].to_i < 1
      db = DataBase.new
      ui = db.getUser(newParams[:user_id].to_i)
      halt 400 if ui.nil?
      c = db.getConsumable(newParams[:item_id].to_i)
      lines = db.editConsumables(newParams[:item_id].to_i, newParams[:name].to_s, newParams[:count].to_i, newParams[:description].to_s, newParams[:repo_id].to_i, newParams[:user_id].to_i)
      if lines > 0
        db.addLog(newParams[:user_id].to_i, '修改耗材', "修改了 #{c[:name]}(#{newParams[:item_id].to_i})")
        status 200
        json_message 0
      elsif lines == -1
        status 200
        json_message 1003, ERRORS[1003]
      else
        400
      end
    end

    settings.post '/api/add_consumables', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :item_id, :user_id, :count)
      halt 400 if newParams[:count].to_i < 1
      db = DataBase.new
      ui = db.getUser(newParams[:user_id].to_i)
      halt 400 if ui.nil?
      c = db.getConsumable(newParams[:item_id].to_i)
      lines = db.setConsumables(newParams[:item_id].to_i, (newParams[:count].to_i * -1))
      if lines > 0
        db.addLog(newParams[:user_id].to_i, '添加耗材', "添加了 #{newParams[:count].to_i} 个 #{c[:name]}(#{newParams[:item_id].to_i})")
        status 200
        json_message 0
      elsif lines == -1
        status 200
        json_message 1003, ERRORS[1003]
      else
        400
      end
    end

    settings.post '/api/use_consumables', :provides => :json do
      content_type :json
      newParams = accept_json_params(request.body, :item_id, :user_id, :count, :reason)
      halt 400 if newParams[:count].to_i < 1  # 如果少于1则阻断
      db = DataBase.new
      ui = db.getUser(newParams[:user_id].to_i)
      halt 400 if ui.nil?
      c = db.getConsumable(newParams[:item_id].to_i)
      lines = db.setConsumables(newParams[:item_id].to_i, newParams[:count].to_i)
      if lines > 0
        db.addLog(newParams[:user_id].to_i, '移除耗材', "移除了 #{newParams[:count].to_i} 个 #{c[:name]}(#{newParams[:item_id].to_i}) 原因: #{newParams[:reason]}")
        db.addRemovedConsumables(newParams[:item_id].to_i, c[:name], newParams[:count].to_i, c[:description], c[:repo_id], newParams[:user_id].to_i, newParams[:reason].to_s, c[:add_time])
        status 200
        json_message 0
      elsif lines == -1
        status 200
        json_message 1003, ERRORS[1003]
      else
        400
      end
    end
  
    settings.get '/api/get_consumable_by_user' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getConsumablesByUser(id)
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end
  
    settings.get '/api/get_consumable_by_repo' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getConsumablesByRepo(id)
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end
  
    settings.get '/api/get_consumable_list' do
      content_type :json
      data = DataBase.new.getConsumableList()
      status 200
      json_data 0, data
    end

    settings.get '/api/get_consumable_list_all' do
      content_type :json
      db = DataBase.new
      data = db.getConsumableListAll()
      list = db.getRepoListIdName()
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:repo_name] = list[item[:repo_id]]
        item 
      end
      status 200
      json_data 0, data
    end
  
    settings.get '/api/get_consumable' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getConsumable(id)
      if !data.nil?
        data[:change_time] = Time.at(data[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        data[:add_time] = Time.at(data[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        status 200
        json_data 0, data
      else
        status 200
        json_data 1003, data, ERRORS[1003]
      end
    end

    settings.get '/api/get_removed_consumable_by_user' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getRemovedConsumablesByUser(id)
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:remove_time] = Time.at(item[:remove_time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end
  
    settings.get '/api/get_removed_consumable_by_repo' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getRemovedConsumablesByRepo(id)
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:remove_time] = Time.at(item[:remove_time]).strftime("%Y-%m-%d %H:%M:%S")
        item 
      end
      status 200
      json_data 0, data
    end
  
    settings.get '/api/get_removed_consumable_list' do
      content_type :json
      db = DataBase.new
      data = db.getRemovedConsumableList()
      list = db.getRepoListIdName()
      data = data.map do |item|
        item[:change_time] = Time.at(item[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:add_time] = Time.at(item[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:remove_time] = Time.at(item[:remove_time]).strftime("%Y-%m-%d %H:%M:%S")
        item[:repo_name] = list[item[:repo_id]]
        item 
      end
      status 200
      json_data 0, data
    end

    settings.get '/api/get_removed_consumable' do
      content_type :json
      newParams = accept_params(params, :id)
      id = newParams[:id]
      halt 400 if id.nil?
      data = DataBase.new.getRemovedConsumable(id)
      data[:change_time] = Time.at(data[:change_time]).strftime("%Y-%m-%d %H:%M:%S")
      data[:remove_time] = Time.at(data[:remove_time]).strftime("%Y-%m-%d %H:%M:%S")
      data[:add_time] = Time.at(data[:add_time]).strftime("%Y-%m-%d %H:%M:%S")
      status 200
      json_data 0, data
    end

    404
  end
end


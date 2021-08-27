require 'sequel'

class DataBase
  def self.connect
    self.new()
  end

  def initialize()
    @db = Sequel.sqlite('./database.db')
    # @db = Sequel.connect(adapter: config[:sql_type], host: config[:sql_host], port: config[:sql_port],
    #                      database: config[:sql_user], user: config[:sql_user], password: config[:sql_password])
  end

  def addUser(name, password)
    @db[:users].where(
        name: name.to_s,
        password: password.to_s
    )
  end

  def getUser(id)
    @db[:users].where(id: id).first
  end

  def addModel(name, type, description)
    @db[:models].insert(
        model_name: name.to_s,
        model_type: type.to_s,
        description: description.to_s
    )
  end

  def getModel(id)
    @db[:models].where(id: id).first
  end

  def getModelList()
    @db[:models].all
  end

  def getLogs(id)
    @db[:logs].where(user_id: id).all
  end

  def addLog(id, type, detial)
    @db[:logs].insert(
        time: Time.now.to_i,
        user_id: id.to_i,
        action_type: type.to_s,
        action_detail: detial.to_s,
    )
  end

  def getRepoList()
    @db[:repo].select(:id, :name).all
  end

  def getRepoInfo(id)
    @db[:repo].where(id: id).all
  end
end
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
  
  def getUsers()
    @db[:users].as_hash(:id, :name)
  end

  def addModel(name, type, description)
    @db[:models].insert(
        model_name: name.to_s,
        model_type: type.to_s,
        description: description.to_s
    )
  end

  def editModel(id, name, type, description)
    @db[:models].where(id: id).update(
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

  def getLogsBylimit(offset, limit)
    @db[:logs].limit(limit, offset)
  end

  def getLogsCount()
    @db[:logs].count
  end

  def getLogsAll()
    @db[:logs].all
  end

  def addLog(id, type, detial)
    @db[:logs].insert(
        time: Time.now.to_i,
        user_id: id.to_i,
        action_type: type.to_s,
        action_detail: detial.to_s,
    )
  end

  def getMachine(id)
    @db[:machines].where(id: id).first
  end

  def getMachines()
    @db[:machines].all
  end

  def getMachinesByUser(id)
    @db[:machines].where(user_id: id).all
  end

  def getMachinesByLab(id)
    @db[:machines].where(lab_id: id).all
  end

  def getMachinesByModel(id)
    @db[:machines].where(model_id: id).all
  end

  def addMachine(description, model_id, user_id, lab_id)
    time = Time.now.to_i
    @db[:machines].insert(
        description: description.to_s,
        model_id: model_id.to_i,
        lab_id: lab_id.to_i,
        add_time: time,
        change_time: time
    )
  end

  def editMachine(id, description, model_id, user_id, lab_id)
    @db[:machines].where(id: id).update(
        description: description.to_s,
        model_id: model_id.to_i,
        lab_id: lab_id.to_i,
        change_time: Time.now.to_i
    )
  end

  def deleteMachine(id)
    @db[:machines].where(id: id).delete
  end

  def getLabList()
    @db[:labs].select(:id, :name).all
  end

  def getLabListAll()
    @db[:labs].all
  end
    
  def getLabListIdName()
    @db[:labs].as_hash(:id, :name)
  end

  def getLabInfo(id)
    @db[:labs].where(id: id).first
  end

  def addLab(name, admin)
    time = Time.now.to_i
    @db[:labs].insert(name: name, admin: admin, addtime: time, change_time: time)
  end

  def editLab(id, name, admin)
    @db[:labs].where(id: id).update(name: name, admin: admin, change_time: Time.now.to_i)
  end

  def deleteLab(id)
    @db[:labs].where(id: id).delete
  end

  def getRepoList()
    @db[:repo].select(:id, :name).all
  end

  def getRepoListAll()
    @db[:repo].all
  end
    
  def getRepoListIdName()
    @db[:repo].as_hash(:id, :name)
  end

  def getRepoInfo(id)
    @db[:repo].where(id: id).first
  end

  def addRepo(name, admin)
    time = Time.now.to_i
    @db[:repo].insert(name: name, admin: admin, add_time: time, change_time: time)
  end

  def editRepo(id, name, admin)
    @db[:repo].where(id: id).update(name: name, admin: admin, change_time: Time.now.to_i)
  end

  def deleteRepo(id)
    @db[:repo].where(id: id).delete
  end

  def addConsumables(name, count, description, repoId, userId)  # 入库
    time = Time.now.to_i
    @db[:consumables].insert(
      name: name.to_s,
      count: count.to_i,
      description: description.to_s,
      repo_id: repoId.to_i,
      user_id: userId.to_i,
      change_time: time,
      add_time: time,
    )
  end

  def editConsumables(id ,name, count, description, repoId, userId)
    @db[:consumables].where(id: id).update(
      name: name.to_s,
      count: count.to_i,
      description: description.to_s,
      repo_id: repoId.to_i,
      user_id: userId.to_i,
      change_time: Time.now.to_i,
    )
  end

  def getConsumableListAll()
    @db[:consumables].all
  end

  def getConsumableList()
    repos = @db[:repo].select(:id).all
    list = {}
    repos.each do |item|
      id = item[:id]
      tmp = getConsumablesByRepo(id.to_i)
      tmp = tmp.map do |c|
        {id: c[:id], name: c[:name], count: c[:count]}
      end
      list[id] = tmp
    end
    return list
  end

  def getConsumablesByRepo(repoId)
    @db[:consumables].where(repo_id: repoId).all
  end

  def getConsumablesByUser(userId)
    @db[:consumables].where(user_id: userId).all
  end

  def getConsumable(id)
    @db[:consumables].where(id: id).first
  end

  def setConsumables(id, count)  # -1 没有此项目，-2错误的传入
    c = getConsumable(id)
    return -1 if c.nil?
    left = c[:count] - count
    if left > 0
      @db[:consumables].where(id: id).update(count: left, change_time: Time.now.to_i)
    elsif left == 0
      @db[:consumables].where(id: id).delete  # 返回删除行数
    elsif left > c[:count]
      tmp = c[:count] + count
      @db[:consumables].where(id: id).update(count: tmp, change_time: Time.now.to_i)
    else
      -2
    end
  end

  def getRemovedConsumable(id)
    @db[:removed_consumables].where(id: id).first
  end

  def addRemovedConsumables(id, name, count, description, repoId, userId, reason, add_time)  #出库记录
    c = getRemovedConsumable(id)
    if c.nil?
      time = Time.now.to_i
      @db[:removed_consumables].insert(
        id: id.to_i,
        name: name.to_s,
        count: count.to_i,
        description: description.to_s,
        repo_id: repoId.to_i,
        user_id: userId.to_i,
        change_time: time,
        remove_time: time,
        add_time: add_time,
        reason: reason.to_s
      )
    else
      tmp = c[:count] + count
      @db[:removed_consumables].where(id: id).update(count: tmp, change_time: Time.now.to_i)
    end
  end

  def getRemovedConsumablesByRepo(repoId)
    @db[:removed_consumables].where(repo_id: repoId).all
  end

  def getRemovedConsumablesByUser(userId)
    @db[:removed_consumables].where(user_id: userId).all
  end

  def getRemovedConsumableList()
    @db[:removed_consumables].all
  end
end

# 10.times {DataBase.new.addConsumables('垃圾鼠标', rand(1..20), '垃圾备注', rand(1..2), 1)}

# p DataBase.new.getConsumableList()
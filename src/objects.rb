class UserAuth
  attr_reader :userId, :userName, :token, :createdTime, :expireSeconds
  def initialize(userId:, userName:, token:, expireSeconds: 36_000)
    @userId = userId
    @userName = userName
    @token = token
    @expireSeconds = expireSeconds
    @createdTime = Time.new
    @expireTime = createdTime + expireSeconds
  end

  def avalable?
    (@expireTime > Time.new)
  end

  def to_hash
    {
      userId: @userId,
      userName: @userName,
      token: @token, 
      createdTime: @createdTime, 
      expireSeconds: @expireSeconds
    }
  end
end

# auth = UserAuth.new(userId: 12_312, token: 'wuifhaiyfhaw', expireSeconds: 10)
# p auth.to_json

# sleep(5)

# p auth.createdTime
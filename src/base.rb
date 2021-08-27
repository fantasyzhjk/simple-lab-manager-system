class Base < Sinatra::Base
  helpers do
    def json_status(code, reason)
      status code if code < 1000
      {
        :code => code,
        :reason => reason
      }.to_json
    end
  end

  not_found do
    status 404
    content_type :json
    json_status 404, 'This is nowhere to be found.'
  end

  error 403 do
    content_type :json
    json_status 403, 'Access forbidden'
  end

  error 400 do
    content_type :json
    json_status 400, 'Bad Request'
  end

  error 401 do
    content_type :json
    json_status 401, "Unauthorized"
  end

  error do
    content_type :json
    json_status 1000, 'Sorry there was a nasty error - ' + env['sinatra.error'].message
  end
end
class RequestHandler
  def process(request)
    Message.send_request(request)
  end
end

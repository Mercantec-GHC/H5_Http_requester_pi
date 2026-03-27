require_relative "lib/boot_loader"

@logger = Logger.new($stdout)
@http_requester = HttpRequester.new(@logger)
@http_requester.execute
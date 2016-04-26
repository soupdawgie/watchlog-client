module Watchlog
  class Sender
    LIMIT   = 10
    RETRIES = 10
    BEFORE_RETRY = 15
    ADDRESS = ENV['POSTFIX_API_ENDPOINT'] || 'http://localhost:9000'
    HTTP_ERRORS = [
                    Errno::ECONNRESET,
                    Errno::EINVAL,
                    Errno::ECONNREFUSED,
                    Timeout::Error
                  ]
    attr_accessor :data

    def initialize
      @data = []
    end

    def process(hash)
      @data << hash
      deliver if should_deliver?
    end

    def should_deliver?
      data.size >= LIMIT
    end

    def payload
      { errors: data.first(LIMIT) }.to_json
    end

    def notify
      uri = URI(ADDRESS)
      req = Net::HTTP::Post.new(uri, initheader = { 'Content-Type' => 'application/json' })
      req.body = payload
      Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    end

    def deliver
      r = RETRIES
      cleanup if notify
    rescue *HTTP_ERRORS => message
      if (r -= 1) > 0
        puts "#{message}\nRetrying..."
        sleep BEFORE_RETRY
        retry
      end
      exit
    end

    def cleanup
      @data.shift(LIMIT)
    end
  end
end

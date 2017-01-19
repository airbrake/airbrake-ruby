module Airbrake
  ##
  # Responsible for sending notices to Airbrake synchronously. Supports proxies.
  #
  # @see AsyncSender
  # @api private
  # @since v1.0.0
  class SyncSender
    ##
    # @return [String] body for HTTP requests
    CONTENT_TYPE = 'application/json'.freeze

    ##
    # @param [Airbrake::Config] config
    def initialize(config)
      @config = config
    end

    ##
    # Sends a POST request to the given +endpoint+ with the +notice+ payload.
    #
    # @param [Airbrake::Notice] notice
    # @param [Airbrake::Notice] endpoint
    # @return [Hash{String=>String}] the parsed HTTP response
    def send(notice, promise, endpoint = @config.endpoint)
      response = nil
      req = build_post_request(endpoint, notice)

      if req.body.nil?
        reason = "#{LOG_LABEL} notice was not sent because of missing body"
        @config.logger.error(reason)
        return promise.reject(reason)
      end

      https = build_https(endpoint)

      begin
        response = https.request(req)
      rescue => ex
        reason = "#{LOG_LABEL} HTTP error: #{ex}"
        @config.logger.error(reason)
        return promise.reject(reason)
      end

      parsed_resp = Response.parse(response, @config.logger)
      return promise.reject(parsed_resp['error']) if parsed_resp.key?('error')
      promise.resolve(parsed_resp)
    end

    private

    def build_https(uri)
      Net::HTTP.new(uri.host, uri.port, *proxy_params).tap do |https|
        https.use_ssl = uri.is_a?(URI::HTTPS)
        if @config.timeout
          https.open_timeout = @config.timeout
          https.read_timeout = @config.timeout
        end
      end
    end

    def build_post_request(uri, notice)
      Net::HTTP::Post.new(uri.request_uri).tap do |req|
        req.body = notice.to_json

        req['Content-Type'] = CONTENT_TYPE
        req['User-Agent'] =
          "#{Airbrake::Notice::NOTIFIER[:name]}/#{Airbrake::AIRBRAKE_RUBY_VERSION}" \
          " Ruby/#{RUBY_VERSION}"
      end
    end

    def proxy_params
      return unless @config.proxy.key?(:host)

      [@config.proxy[:host], @config.proxy[:port], @config.proxy[:user],
       @config.proxy[:password]]
    end
  end
end

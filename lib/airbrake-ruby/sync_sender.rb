module Airbrake
  # Responsible for sending notices to Airbrake synchronously. Supports proxies.
  #
  # @see AsyncSender
  # @api private
  # @since v1.0.0
  class SyncSender
    # @return [String] body for HTTP requests
    CONTENT_TYPE = 'application/json'.freeze

    # @param [Airbrake::Config] config
    def initialize(config)
      @config = config
      @rate_limit_reset = Time.now
    end

    # Sends a POST request to the given +endpoint+ with the +notice+ payload.
    #
    # @param [Airbrake::Notice] notice
    # @param [Airbrake::Notice] endpoint
    # @return [Hash{String=>String}] the parsed HTTP response
    def send(notice, promise, endpoint = @config.endpoint)
      return promise if rate_limited_ip?(promise)

      response = nil
      req = build_post_request(endpoint, notice)

      return promise if missing_body?(req, promise)

      https = build_https(endpoint)

      begin
        response = https.request(req)
      rescue StandardError => ex
        reason = "#{LOG_LABEL} HTTP error: #{ex}"
        @config.logger.error(reason)
        return promise.reject(reason)
      end

      parsed_resp = Response.parse(response, @config.logger)
      if parsed_resp.key?('rate_limit_reset')
        @rate_limit_reset = parsed_resp['rate_limit_reset']
      end

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

        req['Authorization'] = "Bearer #{@config.project_key}"
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

    def rate_limited_ip?(promise)
      rate_limited = Time.now < @rate_limit_reset
      promise.reject("#{LOG_LABEL} IP is rate limited") if rate_limited
      rate_limited
    end

    def missing_body?(req, promise)
      missing = req.body.nil?

      if missing
        reason = "#{LOG_LABEL} notice was not sent because of missing body"
        @config.logger.error(reason)
        promise.reject(reason)
      end

      missing
    end
  end
end

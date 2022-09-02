module Airbrake
  # Responsible for sending data to Airbrake synchronously via PUT or POST
  # methods. Supports proxies.
  #
  # @see AsyncSender
  # @api private
  # @since v1.0.0
  class SyncSender
    # @return [String] body for HTTP requests
    CONTENT_TYPE = 'application/json'.freeze

    # @return [Array<Integer>] response codes that are good to be backlogged
    # @since v6.2.0
    BACKLOGGABLE_STATUS_CODES = [
      Response::BAD_REQUEST,
      Response::FORBIDDEN,
      Response::ENHANCE_YOUR_CALM,
      Response::REQUEST_TIMEOUT,
      Response::CONFLICT,
      Response::TOO_MANY_REQUESTS,
      Response::INTERNAL_SERVER_ERROR,
      Response::BAD_GATEWAY,
      Response::GATEWAY_TIMEOUT,
    ].freeze

    include Loggable

    # @param [Symbol] method HTTP method to use to send payload
    def initialize(method = :post)
      @config = Airbrake::Config.instance
      @method = method
      @rate_limit_reset = Time.now
      @backlog = Backlog.new(self) if @config.backlog
    end

    # Sends a POST or PUT request to the given +endpoint+ with the +data+ payload.
    #
    # @param [#to_json] data
    # @param [URI::HTTPS] endpoint
    # @return [Hash{String=>String}] the parsed HTTP response
    def send(data, promise, endpoint = @config.error_endpoint)
      return promise if rate_limited_ip?(promise)

      req = build_request(endpoint, data)
      return promise if missing_body?(req, promise)

      begin
        response = build_https(endpoint).request(req)
      rescue StandardError => ex
        reason = "#{LOG_LABEL} HTTP error: #{ex}"
        logger.error(reason)
        return promise.reject(reason)
      end

      parsed_resp = Response.parse(response)
      handle_rate_limit(parsed_resp)
      @backlog << [data, endpoint] if add_to_backlog?(parsed_resp)

      return promise.reject(parsed_resp['error']) if parsed_resp.key?('error')

      promise.resolve(parsed_resp)
    end

    # Closes all the resources that this sender has allocated.
    #
    # @return [void]
    # @since v6.2.0
    def close
      @backlog.close
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

    def build_request(uri, data)
      req =
        if @method == :put
          Net::HTTP::Put.new(uri.request_uri)
        else
          Net::HTTP::Post.new(uri.request_uri)
        end

      build_request_body(req, data)
    end

    def build_request_body(req, data)
      req.body = data.to_json

      req['Authorization'] = "Bearer #{@config.project_key}"
      req['Content-Type'] = CONTENT_TYPE
      req['User-Agent'] =
        "#{Airbrake::NOTIFIER_INFO[:name]}/#{Airbrake::AIRBRAKE_RUBY_VERSION} " \
        "Ruby/#{RUBY_VERSION}"

      req
    end

    def handle_rate_limit(parsed_resp)
      return unless parsed_resp.key?('rate_limit_reset')

      @rate_limit_reset = parsed_resp['rate_limit_reset']
    end

    def add_to_backlog?(parsed_resp)
      return unless @backlog
      return unless parsed_resp.key?('code')

      BACKLOGGABLE_STATUS_CODES.include?(parsed_resp['code'])
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
        reason = "#{LOG_LABEL} data was not sent because of missing body"
        logger.error(reason)
        promise.reject(reason)
      end

      missing
    end
  end
end

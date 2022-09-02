module Airbrake
  # Parses responses coming from the Airbrake API. Handles HTTP errors by
  # logging them.
  #
  # @api private
  # @since v1.0.0
  module Response
    # @return [Integer] the limit of the response body
    TRUNCATE_LIMIT = 100

    # @return [Integer] HTTP code returned when the server cannot or will not
    #   process the request due to something that is perceived to be a client
    #   error
    # @since v6.2.0
    BAD_REQUEST = 400

    # @return [Integer] HTTP code returned when client request has not been
    #   completed because it lacks valid authentication credentials for the
    #   requested resource
    # @since v6.2.0
    UNAUTHORIZED = 401

    # @return [Integer] HTTP code returned when the server understands the
    #   request but refuses to authorize it
    # @since v6.2.0
    FORBIDDEN = 403

    # @return [Integer] HTTP code returned when the server would like to shut
    #   down this unused connection
    # @since v6.2.0
    REQUEST_TIMEOUT = 408

    # @return [Integer] HTTP code returned when there's a request conflict with
    #   the current state of the target resource
    # @since v6.2.0
    CONFLICT = 409

    # @return [Integer]
    # @since v6.2.0
    ENHANCE_YOUR_CALM = 420

    # @return [Integer] HTTP code returned when an IP sends over 10k/min notices
    TOO_MANY_REQUESTS = 429

    # @return [Integer] HTTP code returned when the server encountered an
    #   unexpected condition that prevented it from fulfilling the request
    # @since v6.2.0
    INTERNAL_SERVER_ERROR = 500

    # @return [Integer] HTTP code returened when the server, while acting as a
    #   gateway or proxy, received an invalid response from the upstream server
    # @since v6.2.0
    BAD_GATEWAY = 502

    # @return [Integer] HTTP code returened when the server, while acting as a
    #   gateway or proxy, did not get a response in time from the upstream
    #   server that it needed in order to complete the request
    # @since v6.2.0
    GATEWAY_TIMEOUT = 504

    class << self
      include Loggable
    end

    # Parses HTTP responses from the Airbrake API.
    #
    # @param [Net::HTTPResponse] response
    # @return [Hash{String=>String}] parsed response
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def self.parse(response)
      code = response.code.to_i
      body = response.body

      begin
        case code
        when 200, 204
          logger.debug("#{LOG_LABEL} #{name} (#{code}): #{body}")
          { response.msg => response.body }
        when 201
          parsed_body = JSON.parse(body)
          logger.debug("#{LOG_LABEL} #{name} (#{code}): #{parsed_body}")
          parsed_body
        when BAD_REQUEST, UNAUTHORIZED, FORBIDDEN, ENHANCE_YOUR_CALM
          parsed_body = JSON.parse(body)
          logger.error("#{LOG_LABEL} #{parsed_body['message']}")
          parsed_body.merge('code' => code, 'error' => parsed_body['message'])
        when TOO_MANY_REQUESTS
          parsed_body = JSON.parse(body)
          msg = "#{LOG_LABEL} #{parsed_body['message']}"
          logger.error(msg)
          {
            'code' => code,
            'error' => msg,
            'rate_limit_reset' => rate_limit_reset(response),
          }
        else
          body_msg = truncated_body(body)
          logger.error("#{LOG_LABEL} unexpected code (#{code}). Body: #{body_msg}")
          { 'code' => code, 'error' => body_msg }
        end
      rescue StandardError => ex
        body_msg = truncated_body(body)
        logger.error("#{LOG_LABEL} error while parsing body (#{ex}). Body: #{body_msg}")
        { 'code' => code, 'error' => ex.inspect }
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def self.truncated_body(body)
      if body.nil?
        '[EMPTY_BODY]'.freeze
      elsif body.length > TRUNCATE_LIMIT
        body[0..TRUNCATE_LIMIT] << '...'
      else
        body
      end
    end
    private_class_method :truncated_body

    def self.rate_limit_reset(response)
      Time.now + response['X-RateLimit-Delay'].to_i
    end
    private_class_method :rate_limit_reset
  end
end

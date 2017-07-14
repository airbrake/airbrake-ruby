module Airbrake
  ##
  # Parses responses coming from the Airbrake API. Handles HTTP errors by
  # logging them.
  #
  # @api private
  # @since v1.0.0
  module Response
    ##
    # @return [Integer] the limit of the response body
    TRUNCATE_LIMIT = 100

    ##
    # Parses HTTP responses from the Airbrake API.
    #
    # @param [Net::HTTPResponse] response
    # @param [Logger] logger
    # @return [Hash{String=>String}] parsed response
    def self.parse(response, logger)
      code = response.code.to_i
      body = response.body

      begin
        case code
        when 201
          parsed_body = JSON.parse(body)
          logger.debug("#{LOG_LABEL} #{parsed_body}")
          parsed_body
        when 400, 401, 403, 429
          parsed_body = JSON.parse(body)
          logger.error("#{LOG_LABEL} #{parsed_body['message']}")
          parsed_body
        else
          body_msg = truncated_body(body)
          logger.error("#{LOG_LABEL} unexpected code (#{code}). Body: #{body_msg}")
          { 'error' => body_msg }
        end
      rescue => ex
        body_msg = truncated_body(body)
        logger.error("#{LOG_LABEL} error while parsing body (#{ex}). Body: #{body_msg}")
        { 'error' => ex.inspect }
      end
    end

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
  end
end

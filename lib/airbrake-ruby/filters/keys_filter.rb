module Airbrake
  module Filters
    ##
    # This is a filter helper that endows a class ability to filter notices'
    # payload based on the return value of the +should_filter?+ method that a
    # class that includes this module must implement.
    #
    # @see Notice
    # @see KeysWhitelist
    # @see KeysBlacklist
    module KeysFilter
      ##
      # @return [String] The label to replace real values of filtered payload
      FILTERED = '[Filtered]'.freeze

      ##
      # Creates a new KeysBlacklist or KeysWhitelist filter that uses the given
      # +patterns+ for filtering a notice's payload.
      #
      # @param [Array<String,Regexp,Symbol>] patterns
      def initialize(*patterns)
        @patterns = patterns
      end

      ##
      # This is a mandatory method required by any filter integrated with
      # FilterChain.
      #
      # @param [Notice] notice the notice to be filtered
      # @return [void]
      # @see FilterChain
      def call(notice)
        FILTERABLE_KEYS.each { |key| filter_hash(notice[key]) }

        if notice[:context][:user] && should_filter?(:user)
          notice[:context][:user] = FILTERED
        end

        return unless notice[:context][:url]
        filter_url(notice)
      end

      ##
      # @raise [NotImplementedError] if called directly
      def should_filter?(_key)
        raise NotImplementedError, 'method must be implemented in the included class'
      end

      private

      def filter_hash(hash)
        hash.each_key do |key|
          if should_filter?(key)
            hash[key] = FILTERED
          elsif hash[key].is_a?(Hash)
            filter_hash(hash[key])
          end
        end
      end

      def filter_url_params(url)
        url.query = Hash[URI.decode_www_form(url.query)].map do |key, val|
          # Ruby < 2.2 raises InvalidComponentError if the query contains
          # invalid characters, so be sure to escape individual components.
          if should_filter?(key)
            "#{URI.encode_www_form_component(key)}=[Filtered]"
          else
            "#{URI.encode_www_form_component(key)}=#{URI.encode_www_form_component(val)}"
          end
        end.join('&')

        url.to_s
      end

      def filter_url(notice)
        begin
          url = URI(notice[:context][:url])
        rescue URI::InvalidURIError
          return
        end

        return unless url.query
        notice[:context][:url] = filter_url_params(url)
      end
    end
  end
end

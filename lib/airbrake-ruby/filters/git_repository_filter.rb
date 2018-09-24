module Airbrake
  module Filters
    # Attaches git repository URL to `context`.
    # @api private
    # @since v2.12.0
    class GitRepositoryFilter
      # @return [Integer]
      attr_reader :weight

      # @param [String] root_directory
      def initialize(root_directory)
        @git_path = File.join(root_directory, '.git')
        @repository = nil
        @weight = 116
      end

      # @macro call_filter
      def call(notice)
        return if notice[:context].key?(:repository)

        if @repository
          notice[:context][:repository] = @repository
          return
        end

        return unless File.exist?(@git_path)

        @repository = `cd #{@git_path} && git remote get-url origin`.chomp
        return unless @repository
        notice[:context][:repository] = @repository
      end
    end
  end
end

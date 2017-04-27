module Airbrake
  module Filters
    ##
    # Attaches thread & fiber local variables along with general thread
    # information.
    class ThreadFilter
      def call(notice)
        th = Thread.current
        thread_info = {}

        if (vars = thread_variables(th)).any?
          thread_info[:thread_variables] = vars
        end

        if (vars = fiber_variables(th)).any?
          thread_info[:fiber_variables] = vars
        end

        # Present in Ruby 2.3+.
        if th.respond_to?(:name) && (name = th.name)
          thread_info[:name] = name
        end

        add_thread_info(th, thread_info)

        notice[:params][:thread] = thread_info
      end

      private

      def thread_variables(th)
        th.thread_variables.map.with_object({}) do |var, h|
          h[var] = th.thread_variable_get(var).inspect
        end
      end

      def fiber_variables(th)
        th.keys.map.with_object({}) { |key, h| h[key] = th[key].inspect }
      end

      def add_thread_info(th, thread_info)
        thread_info[:self] = th.inspect
        thread_info[:group] = th.group.list.map(&:inspect)
        thread_info[:priority] = th.priority

        thread_info[:safe_level] = th.safe_level unless Airbrake::JRUBY
      end
    end
  end
end

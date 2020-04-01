require_relative "notifier"

module ActiveMonitoring
  class Notifications
    class << self
      attr_accessor :notifier

      def subscribe(name, &block)
        notifier.subscribe(name, &block)
      end

      def instrument(name, payload = {}, &block)
        notifier.instrument(name, payload, &block)
      end
    end

    self.notifier = ActiveMonitoring::Notifier.new
  end
end

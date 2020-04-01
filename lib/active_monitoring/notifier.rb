module ActiveMonitoring
  class Notifier
    def initialize
      @subscribers = {}
    end

    def subscribe(name, &block)
      subscribers[name] ||= []
      subscribers[name] << block
    end

    def instrument(name, payload)
      id = SecureRandom.hex(10)
      start = Time.current
      result = yield if block_given?
      finish = Time.current

      subscribers_for(name).each do |callback|
        callback.call(name, start, finish, id, payload)
      end

      result
    end

    private

      attr_reader :subscribers

      def subscribers_for(name)
        subscribers[name].to_a
      end
  end
end

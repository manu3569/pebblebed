require 'json'
require 'bunny'
require 'pebblebed/river/subscription'

module Pebblebed
  module River

    class << self

      def bunny
        @bunny ||= Bunny.new
      end

      def connected?
        bunny.connected?
      end

      def connect
        bunny.start unless bunny.connected?
      end

      def disconnect
        bunny.stop
      end

      def publish(options = {})
        connect
        key = route(options)
        exchange.publish(options.to_json, :persistent => true, :key => key)
      end

      def exchange
        connect

        @exchange ||= bunny.exchange('pebblebed.river', :type => :topic, :durable => :true)
      end

      def queue_me(name = nil, options = {})
        connect
        name ||= random_name

        queue = bunny.queue(name)
        Subscription.new(options).queries.each do |key|
          queue.bind(exchange.name, :key => key)
        end
        queue
      end

      def random_name
        Digest::SHA1.hexdigest(rand(10 ** 10).to_s)
      end

      def purge
        q = queue_me
        q.purge
        q.delete
        true
      end

      def route(options)
        raise ArgumentError.new(':event is required') unless options[:event]
        raise ArgumentError.new(':uid is required') unless options[:uid]

        uid = Pebblebed::Uid.new(options[:uid])
        key = [options[:event], uid.klass, uid.path].compact
        key.join('._.')
      end

    end

  end
end
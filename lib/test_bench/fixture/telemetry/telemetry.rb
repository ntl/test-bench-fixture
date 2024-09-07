module TestBench
  module Fixture
    class Telemetry
      RegistrationError = Class.new(RuntimeError)
      GetError = Class.new(RuntimeError)

      def sinks
        @sinks ||= []
      end
      attr_writer :sinks

      def self.build(*sinks)
        instance = new

        sinks.each do |sink|
          instance.register(sink)
        end

        instance
      end

      def self.configure(receiver, *sinks, attr_name: nil)
        attr_name ||= :telemetry

        instance = build(*sinks)
        receiver.public_send(:"#{attr_name}=", instance)
      end

      def record(event)
        if event.is_a?(Event)
          event.metadata ||= Event::Metadata.new

          event_data = Event::Export.(event)
        else
          event_data = event
        end

        event_data.process_id ||= process_id
        event_data.time ||= current_time

        sinks.each do |sink|
          sink.receive(event_data)
        end

        event_data
      end

      def current_time
        self.class.current_time
      end

      def process_id
        self.class.process_id
      end

      def self.current_time
        ::Time.now
      end

      def self.process_id
        ::Process.pid
      end

      def register(sink)
        if registered?(sink)
          raise RegistrationError, "Already registered #{sink.inspect}"
        end

        sinks.push(sink)
      end

      def unregister(sink)
        deleted_sink = sinks.delete(sink)

        if deleted_sink.nil?
          raise RegistrationError, "Not registered #{sink.inspect}"
        end
      end

      def registered?(sink_or_sink_class)
        if sink_or_sink_class.is_a?(Sink)
          sink = sink_or_sink_class

          sinks.include?(sink)
        else
          sink_class = sink_or_sink_class

          sink = get_sink(sink_class)

          !sink.nil?
        end
      end

      def get_sink(sink_class)
        sink, *other_sinks = get_sinks(sink_class)

        if other_sinks.any?
          raise GetError, "Multiple sinks match: #{sink_class.inspect}"
        end

        sink
      end

      def get_sinks(sink_class)
        sinks.select do |sink|
          sink.instance_of?(sink_class)
        end
      end
    end
  end
end

module TestBench
  module Fixture
    class Telemetry
      module Substitute
        class Sink
          MatchError = Class.new(RuntimeError)

          include Telemetry::Sink

          def self.read(path)
            file_text = ::File.read(path)

            instance = new

            file_text.each_line do |event_data_text|
              event_data = Telemetry::EventData.load(event_data_text)

              instance.receive(event_data)
            end

            instance
          end

          def received_events
            @received_events ||= []
          end

          def receive(event_data)
            received_events << event_data
          end

          def received?(event_data)
            received_events.include?(event_data)
          end

          def one_event?(...)
            !one_event(...).nil?
          end

          def one_event(...)
            events = events(...)

            if events.count > 1
              event_type = events.first.event_type
              raise MatchError, "More than one event matches (Type: #{event_type.inspect}, Matching Events: #{events.count})"
            end

            events.first
          end

          def any_event?(...)
            events(...).any?
          end
          alias :event? :any_event?

          def events(event_class, **attributes)
            event_type = event_class.event_type

            events = []

            received_events.each do |event_data|
              event_types_correspond = event_data.type == event_type

              if event_types_correspond
                event = Event::Import.(event_data, event_class)

                attributes_correspond = attributes.all? do |attribute, compare_value|
                  value = event.public_send(attribute)

                  value == compare_value
                end

                if attributes_correspond
                  events << event
                end
              end
            end

            events
          end
        end
      end
    end
  end
end

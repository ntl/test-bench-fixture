module TestBench
  module Fixture
    class Telemetry
      module Sink
        module Handler
          class EventRegistry
            Error = Class.new(RuntimeError)

            def event_classes
              @event_classes ||= {}
            end
            attr_writer :event_classes

            def event_types
              event_classes.keys
            end

            def get(event_type)
              event_classes.fetch(event_type) do
                raise Error, "#{event_type} isn't registered"
              end
            end

            def register(event_class)
              if registered?(event_class)
                raise Error, "#{event_class} is already registered"
              end

              event_type = event_class.event_type

              event_classes[event_type] = event_class
            end

            def registered?(event_class)
              event_type = event_class.event_type

              event_classes.key?(event_type)
            end
          end
        end
      end
    end
  end
end

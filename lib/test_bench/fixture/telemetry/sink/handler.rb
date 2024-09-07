module TestBench
  module Fixture
    class Telemetry
      module Sink
        module Handler
          def self.included(cls)
            cls.class_exec do
              include Sink
              include Receive

              extend HandlerMethod
              extend HandleMacro
            end
          end

          module Receive
            def receive(event_data)
              handle(event_data)
            end
          end

          def handle(event_or_event_data)
            handles = handle?(event_or_event_data)

            if handles
              if event_or_event_data.is_a?(Event)
                event = event_or_event_data
              else
                event_data = event_or_event_data
                event_type = event_data.type
                event_class = self.class.event_registry.get(event_type)

                event = Event::Import.(event_data, event_class)
              end

              handler_method = handler_method(event)

              if method(handler_method).parameters.any?
                __send__(handler_method, event)
              else
                __send__(handler_method)
              end

              event
            elsif respond_to?(:handle_event_data)
              if event_or_event_data.is_a?(Event)
                event_data = Event::Export.(event_or_event_data)
              else
                event_data = event_or_event_data
              end

              handle_event_data(event_data)

              event_data
            else
              nil
            end
          end

          def handle?(...)
            handler_method = handler_method(...)

            not handler_method.nil?
          end

          def handler_method(event_or_event_data)
            handler_method = self.class.handler_method(event_or_event_data)

            if respond_to?(handler_method)
              handler_method
            else
              nil
            end
          end

          module HandleMacro
            def handle_macro(event_class, &block)
              event_registry.register(event_class)

              event_type = event_class.event_type

              handler_method = HandlerMethod.get(event_type)

              define_method(handler_method, &block)
            end
            alias :handle :handle_macro

            def event_registry
              @event_registry ||= EventRegistry.new
            end
          end

          module HandlerMethod
            def handler_method(event_or_event_data)
              if event_or_event_data.is_a?(Event)
                event = event_or_event_data
                event_type = event.event_type
              else
                event_data = event_or_event_data
                event_type = event_data.type
              end

              HandlerMethod.get(event_type)
            end

            def self.get(event_type)
              handler_methods[event_type]
            end

            def self.handler_methods
              @handler_methods ||= Hash.new do |handler_methods, event_type|
                handler_method = get!(event_type)

                handler_methods[event_type] = handler_method
              end
            end

            def self.get!(event_type)
              event_name = Event::EventName.get(event_type)

              :"handle_#{event_name}"
            end
          end
        end
      end
    end
  end
end

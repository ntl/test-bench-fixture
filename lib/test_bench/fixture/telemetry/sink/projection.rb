module TestBench
  module Fixture
    class Telemetry
      module Sink
        module Projection
          def self.included(cls)
            cls.class_exec do
              include Sink
              include Receive

              extend ReceiverNameMacro

              extend ApplyMethod
              extend ApplyMacro
            end
          end

          attr_accessor :receiver

          def initialize(receiver)
            @receiver = receiver
          end

          module Receive
            def receive(event_data)
              apply(event_data)
            end
          end

          def apply(event_or_event_data)
            applies = apply?(event_or_event_data)

            if applies
              if event_or_event_data.is_a?(Event)
                event = event_or_event_data
              else
                event_data = event_or_event_data
                event_type = event_data.type
                event_class = self.class.event_registry.get(event_type)

                event = Event::Import.(event_data, event_class)
              end

              apply_method = apply_method(event)

              if method(apply_method).parameters.any?
                __send__(apply_method, event)
              else
                __send__(apply_method)
              end

              event
            elsif respond_to?(:apply_event_data)
              if event_or_event_data.is_a?(Event)
                event_data = Event::Export.(event_or_event_data)
              else
                event_data = event_or_event_data
              end

              apply_event_data(event_data)

              event_data
            else
              nil
            end
          end
          alias :call :apply

          def apply?(...)
            apply_method = apply_method(...)

            not apply_method.nil?
          end

          def apply_method(event_or_event_data)
            apply_method = self.class.apply_method(event_or_event_data)

            if respond_to?(apply_method)
              apply_method
            else
              nil
            end
          end

          module ReceiverNameMacro
            def receiver_name_macro(receiver_name)
              define_method(receiver_name) do
                receiver
              end
            end
            alias :receiver_name :receiver_name_macro
          end

          module ApplyMacro
            def apply_macro(event_class, &block)
              event_registry.register(event_class)

              event_type = event_class.event_type

              apply_method = ApplyMethod.get(event_type)

              define_method(apply_method, &block)
            end
            alias :apply :apply_macro

            def event_registry
              @event_registry ||= Handler::EventRegistry.new
            end
          end

          module ApplyMethod
            def apply_method(event_or_event_data)
              if event_or_event_data.is_a?(Event)
                event = event_or_event_data
                event_type = event.event_type
              else
                event_data = event_or_event_data
                event_type = event_data.type
              end

              ApplyMethod.get(event_type)
            end

            def self.get(event_type)
              event_name = Event::EventName.get(event_type)

              :"apply_#{event_name}"
            end
          end
        end
      end
    end
  end
end

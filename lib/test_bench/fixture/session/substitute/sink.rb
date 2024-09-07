module TestBench
  module Fixture
    class Session
      module Substitute
        class Sink
          include Telemetry::Sink
          include Events

          def records
            @records ||= []
          end
          attr_writer :records

          def path
            @path ||= Path.new
          end
          attr_writer :path

          def receive(event_data)
            event_type = event_data.type

            case event_type
            when :TestStarted, :ContextStarted
              title, * = event_data.data
              if not title.nil?
                path.push(title)
              end

            when :TestFinished, :ContextFinished
              title, * = event_data.data
              if not title.nil?
                path.pop(title)
              end
            end

            record = Record.new(event_data)
            path.copy(record)

            case event_type
            when :TestFinished, :ContextFinished
              title, * = event_data.data
              if not title.nil?
                record.path.push(title)
              end

            when :Commented, :Detailed
              comment_text, * = event_data.data
              record.path.push(comment_text)
            end

            records.push(record)

            record
          end

          def received?(event_data=nil)
            if not event_data.nil?
              records.any? do |record|
                record.event_data == event_data
              end
            else
              records.any?
            end
          end

          def one_event?(event_class, *path_segments, **attributes)
            event_sink = event_sink(*path_segments)
            event_sink.one_event?(event_class, **attributes)
          end

          def one_event(event_class, *path_segments, **attributes)
            event_sink = event_sink(*path_segments)
            event_sink.one_event(event_class, **attributes)
          end

          def any_event?(event_class, *path_segments, **attributes)
            event_sink = event_sink(*path_segments)
            event_sink.any_event?(event_class, **attributes)
          end
          alias :event? :any_event?

          def events(event_class, *path_segments, **attributes)
            event_sink = event_sink(*path_segments)
            event_sink.events(event_class, **attributes)
          end

          def event_sink(*path_segments)
            event_sink = Telemetry::Substitute::Sink.new

            records.each do |record|
              if record.match?(path_segments)
                event_data = record.event_data

                event_sink.receive(event_data)
              end
            end

            event_sink
          end

          Record = Struct.new(:event_data, :path) do
            def match?(path_segments)
              if path_segments.any?
                path.match?(*path_segments)
              else
                true
              end
            end
          end
        end
      end
    end
  end
end

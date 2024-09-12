module TestBench
  module Fixture
    class Session
      module GetOutput
        Error = Class.new(RuntimeError)

        def self.call(substitute_session, styling: nil)
          styling ||= false

          if not substitute_session.respond_to?(:sink)
            raise Error, "Not a substitute session"
          end

          session_sink = substitute_session.sink

          output = Output.new

          if styling
            output.writer.styling!
          end

          session_sink.records.each do |record|
            event_data = record.event_data

            output.receive(event_data)
          end

          output.writer.written_text
        end
      end
    end
  end
end

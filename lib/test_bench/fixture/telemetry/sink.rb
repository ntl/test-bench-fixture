module TestBench
  module Fixture
    class Telemetry
      module Sink
        ReceiveError = Class.new(RuntimeError)

        def receive(event_data)
          raise ReceiveError, "Sink #{self.class} doesn't implement receive"
        end
      end
    end
  end
end

module TestBench
  module Fixture
    class Session
      class Projection
        include Telemetry::Sink::Projection
        include Events

        receiver_name :session

        apply Failed do
          session.record_failure
        end

        apply TestSkipped do
          session.record_skip
        end

        apply ContextSkipped do
          session.record_skip
        end

        apply TestFinished do |test_finished|
          if test_finished.result
            session.record_assertion
          end
        end
      end
    end
  end
end

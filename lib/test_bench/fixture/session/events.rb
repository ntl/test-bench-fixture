module TestBench
  module Fixture
    class Session
      module Events
        def self.each_type(&block)
          constants(false).each(&block)
        end

        Failed = Fixture::Telemetry::Event.define(:message)

        ContextStarted = Fixture::Telemetry::Event.define(:title)
        ContextFinished = Fixture::Telemetry::Event.define(:title, :result)
        ContextSkipped = Fixture::Telemetry::Event.define(:title)

        TestStarted = Fixture::Telemetry::Event.define(:title)
        TestFinished = Fixture::Telemetry::Event.define(:title, :result)
        TestSkipped = Fixture::Telemetry::Event.define(:title)

        Commented = Fixture::Telemetry::Event.define(:text, :quote, :heading)
        Detailed = Fixture::Telemetry::Event.define(:text, :quote, :heading)

        FixtureStarted = Fixture::Telemetry::Event.define(:name)
        FixtureFinished = Fixture::Telemetry::Event.define(:name, :result)
      end
    end
  end
end

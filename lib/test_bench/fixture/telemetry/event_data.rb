module TestBench
  module Fixture
    class Telemetry
      EventData = Struct.new(:type, :process_id, :time, :data) do
        def self.load(text)
          EventData::Serialization.load(text)
        end

        def dump
          EventData::Serialization.dump(self)
        end
      end
    end
  end
end

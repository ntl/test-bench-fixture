module TestBench
  module Fixture
    class Evaluate
      include Fixture

      attr_reader :block

      def initialize(block)
        @block = block
      end

      def self.build(session:, &block)
        instance = new(block)
        Session.configure(instance, session:, attr_name: :test_session)
        instance
      end

      def self.call(session: nil, &block)
        instance = build(session:, &block)
        instance.()
        instance
      end

      def call
        instance_exec(&block)
      end
    end
  end
end

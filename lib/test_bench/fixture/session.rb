module TestBench
  module Fixture
    class Session
      Failure = Class.new(RuntimeError)
      Abort = Class.new(Failure)

      def telemetry
        @telemetry ||= Fixture::Telemetry::Substitute.build
      end
      attr_writer :telemetry

      def failure_sequence
        @failure_sequence ||= 0
      end
      attr_writer :failure_sequence

      def assertion_sequence
        @assertion_sequence ||= 0
      end
      attr_writer :assertion_sequence

      def skip_sequence
        @skip_sequence ||= 0
      end
      attr_writer :skip_sequence

      def self.build(&block)
        instance = new

        Telemetry.configure(instance)

        if not block.nil?
          block.(instance.telemetry)
        end

        instance
      end

      def self.configure(receiver, session: nil, attr_name: nil, &block)
        session ||= Store.fetch
        attr_name ||= :session

        instance = session
        receiver.public_send(:"#{attr_name}=", instance)
      end

      def inspect
        text = self.to_s

        instance_variables = self.instance_variables - [:@telemetry]

        instance_variables.each_with_index do |name, index|
          ivar_text = String.new

          if index > 0
            ivar_text << ','
          end

          value = instance_variable_get(name)
          value = value.inspect

          ivar_text << " #{name}=#{value}"

          text.insert(-2, ivar_text)
        end

        text
      end

      def passed?
        if failed?
          false
        elsif asserted? && !skipped?
          true
        else
          nil
        end
      end

      def fixture(name, &block)
        original_failure_sequence = failure_sequence

        record_event(Events::FixtureStarted.new(name))

        begin
          block.()

        rescue Failure

        ensure
          result = !failed?(original_failure_sequence)

          record_event(Events::FixtureFinished.new(name, result))
        end

        result
      end

      def detail(text, indent_style, heading=nil)
        record_event(Events::Detailed.new(text, heading, indent_style))
      end

      def comment(text, indent_style, heading=nil)
        record_event(Events::Commented.new(text, heading, indent_style))
      end

      def context!(...)
        if context(...) == false
          message = Session.abort_message
          raise Abort, message
        end
      end

      def context(title=nil, &block)
        if block.nil?
          record_skip
          record_event(Events::ContextSkipped.new(title))
          return
        end

        original_failure_sequence = failure_sequence

        record_event(Events::ContextStarted.new(title))

        begin
          block.()

        rescue Failure

        ensure
          result = !failed?(original_failure_sequence)

          record_event(Events::ContextFinished.new(title, result))
        end

        result
      end

      def test!(...)
        if test(...) == false
          message = Session.abort_message
          raise Abort, message
        end
      end

      def test(title=nil, &block)
        if block.nil?
          record_skip
          record_event(Events::TestSkipped.new(title))
          return
        end

        original_failure_sequence = failure_sequence
        original_assertion_sequence = assertion_sequence

        record_event(Events::TestStarted.new(title))

        begin
          block.()

          result = !failed?(original_failure_sequence)

          if result
            if not asserted?(original_assertion_sequence)
              failure_message = Session.no_assertion_message
              fail(failure_message)
            end
          end

        rescue Failure
          result = false

        ensure
          record_event(Events::TestFinished.new(title, result))
        end

        result
      end

      def assert(result)
        failure_message = Session.assertion_failure_message

        record_assertion

        if result == false
          fail(failure_message)
        end
      end

      def fail(message=nil)
        message ||= self.class.default_failure_message

        record_failure

        record_event(Events::Failed.new(message))

        raise Failure, message
      end

      def asserted?(compare_sequence=nil)
        compare_sequence ||= 0

        compare_sequence != assertion_sequence
      end

      def register_telemetry_sink(telemetry_sink)
        telemetry.register(telemetry_sink)
      end

      def record_assertion
        self.assertion_sequence += 1
      end

      def failed?(compare_sequence=nil)
        compare_sequence ||= 0

        compare_sequence != failure_sequence
      end

      def record_event(event)
        telemetry.record(event)
      end

      def record_failure
        self.failure_sequence += 1
      end

      def skipped?
        skip_sequence != 0
      end

      def record_skip
        self.skip_sequence += 1
      end

      def self.default_failure_message
        'Failed'
      end

      def self.assertion_failure_message
        "Assertion failed"
      end

      def self.abort_message
        "Abort"
      end

      def self.no_assertion_message
        "Test didn't perform an assertion"
      end
    end
  end
end

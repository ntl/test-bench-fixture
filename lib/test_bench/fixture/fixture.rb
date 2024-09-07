module TestBench
  module Fixture
    include Session::Events

    def test_session
      @test_session ||= Session::Substitute.build
    end
    attr_writer :test_session

    def fixture_passed?
      test_session.passed?
    end
    alias :passed? :fixture_passed?

    def comment(...)
      Fixture.comment(test_session.telemetry, Commented, ...)
    end

    def detail(...)
      Fixture.comment(test_session.telemetry, Detailed, ...)
    end

    def assert(result)
      if not [true, false, nil].include?(result)
        raise TypeError, "Value #{result.inspect} isn't a boolean"
      end

      result = false if result.nil?

      test_session.assert(result)
    end

    def refute(result)
      if not [true, false, nil].include?(result)
        raise TypeError, "Value #{result.inspect} isn't a boolean"
      end

      negated_result = !result

      test_session.assert(negated_result)
    end

    def assert_raises(exception_class=nil, message=nil, strict: nil, &block)
      if exception_class.nil?
        strict ||= false
        exception_class = StandardError
      else
        strict = true if strict.nil?
      end

      detail "Expected exception: #{exception_class}#{' (strict)' if strict}"
      if not message.nil?
        detail "Expected message: #{message.inspect}"
      end

      block.()

      detail "(No exception was raised)"

    rescue exception_class => exception

      detail "Raised exception: #{exception.inspect}#{" (subclass of #{exception_class})" if exception.class < exception_class}"

      if strict && !exception.instance_of?(exception_class)
        raise exception
      end

      if message.nil?
        result = true
      else
        result = exception.message == message
      end

      assert(result)
    else
      assert(false)
    end

    def refute_raises(exception_class=nil, strict: nil, &block)
      if exception_class.nil?
        strict ||= false
        exception_class = StandardError
      else
        strict = true if strict.nil?
      end

      detail "Prohibited exception: #{exception_class}#{' (strict)' if strict}"

      block.()

      detail "(No exception was raised)"

    rescue exception_class => exception

      detail "Raised exception: #{exception.inspect}#{" (subclass of #{exception_class})" if exception.class < exception_class}"

      if strict && !exception.instance_of?(exception_class)
        raise exception
      end

      assert(false)
    else
      assert(true)
    end

    def context(title=nil, &block)
      title = title&.to_str

      test_session.context(title, &block)
    end

    def context!(title=nil, &block)
      title = title&.to_str

      test_session.context!(title, &block)
    end

    def test(title=nil, &block)
      title = title&.to_str

      test_session.test(title, &block)
    end

    def test!(title=nil, &block)
      title = title&.to_str

      test_session.test!(title, &block)
    end

    def fail!(message=nil)
      test_session.fail(message)
    end

    def fixture(fixture_class_or_object, *, **, &)
      session = self.test_session

      Fixture.(fixture_class_or_object, *, session:, **, &)
    end

    def self.comment(telemetry, event_class, text, *additional_texts, heading: nil, quote: nil)
      texts = [text, *additional_texts]

      texts.map! do |text|
        text.to_str
      end

      if quote.nil?
        quote = texts.last.end_with?("\n")
      end

      if quote
        if heading.nil?
          heading = !text.end_with?("\n")
        end
      end

      if heading
        heading = texts.shift
      else
        heading = nil
      end

      if quote
        text = texts.join
      else
        text = texts.first
      end

      event = event_class.new
      event.text = text
      event.quote = quote
      event.heading = heading

      telemetry.record(event)

      if not quote
        texts[1..-1].each do |text|
          comment(telemetry, event_class, text, heading: false, quote: false)
        end
      end
    end

    def self.output(fixture, styling: nil)
      session = fixture.test_session

      Session::Output::Get.(session, styling:)
    end

    def self.call(fixture_class_or_object, ...)
      if fixture_class_or_object.instance_of?(Class)
        fixture_class = fixture_class_or_object
        Actuate::Class.(fixture_class, ...)
      else
        object = fixture_class_or_object
        Actuate::Object.(object, ...)
      end
    end
  end
end

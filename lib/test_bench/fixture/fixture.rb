module TestBench
  module Fixture
    include Events

    def test_session
      @test_session ||= Session::Substitute.build
    end
    attr_writer :test_session

    def fixture_passed?
      test_session.passed?
    end
    alias :passed? :fixture_passed?

    def comment(heading=nil, text, indent: nil)
      text = text.to_str
      heading = heading&.to_str
      indent_style = indent

      test_session.comment(text, indent_style, heading)
    end

    def detail(heading=nil, text, indent: nil)
      text = text.to_str
      heading = heading&.to_str
      indent_style = indent

      test_session.detail(text, indent_style, heading)
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

    def self.output(fixture, styling: nil)
      session = fixture.test_session

      Session::GetOutput.(session, styling:)
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

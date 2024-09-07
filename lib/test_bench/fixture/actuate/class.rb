module TestBench
  module Fixture
    module Actuate
      module Class
        Error = ::Class.new(RuntimeError)

        def self.call(fixture_class, *, session: nil, **, &block)
          if test_block?(fixture_class)
            test_block = block
          else
            block_actuator = block
          end

          fixture = build_fixture(fixture_class, *, **, &test_block)

          Session.configure(fixture, session:, attr_name: :test_session)

          actuate(fixture, &block_actuator)

          fixture
        end

        def self.actuate(fixture, &block_actuator)
          if fixture.respond_to?(:call)
            fixture_actuator = fixture
          end

          if block_actuator && fixture_actuator
            raise Error, "Block argument given to fixture that has an actuator (Fixture Class: #{fixture.class})"
          end

          if block_actuator.nil? && fixture_actuator.nil?
            raise Error, "No actuator"
          end

          if not block_actuator.nil?
            block_actuator.(fixture)
          else
            fixture_actuator.()
          end
        end

        def self.build_fixture(fixture_class, ...)
          constructor = constructor(fixture_class)

          fixture_class.public_send(constructor, ...)
        end

        def self.test_block?(fixture_class)
          assure_fixture(fixture_class)

          constructor = constructor(fixture_class)

          if constructor == :build
            constructor_method = fixture_class.method(:build)
          else
            constructor_method = fixture_class.instance_method(:initialize)
          end

          constructor_parameters = constructor_method.parameters

          constructor_parameters.any? do |(type, _)|
            type == :block
          end
        end

        def self.constructor(fixture_class)
          assure_fixture(fixture_class)

          if fixture_class.respond_to?(:build)
            :build
          else
            :new
          end
        end

        def self.assure_fixture(fixture_class)
          is_class = fixture_class.instance_of?(::Class)

          if not is_class
            raise Error, "Not a class (Class: #{fixture_class})"
          end

          if is_class
            is_fixture_class = fixture_class.included_modules.include?(Fixture)
          end

          if not is_fixture_class
            raise Error, "Not a fixture class (Class: #{fixture_class})"
          end
        end
      end
    end
  end
end

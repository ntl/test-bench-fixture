module TestBench
  module Fixture
    module Actuate
      module Object
        ModuleError = ::Class.new(RuntimeError)

        def self.call(object, *modules, session: nil, &block_actuator)
          extend(object, *modules)

          Session.configure(object, session:, attr_name: :test_session)

          block_actuator.(object)
        end

        def self.extend(object, *modules)
          if modules.empty?
            fixture_modules = fixture_modules(object)
          else
            fixture_modules = modules.map do |mod|
              assure_included(object, mod)

              fixture_module(mod)
            end
          end

          if fixture_modules.empty?
            raise ModuleError, "No Fixture modules found -- #{object.inspect}"
          end

          fixture_modules.each do |fixture_module|
            object.extend(fixture_module)
          end

          object.extend(Fixture)
        end

        def self.assure_included(object, mod)
          if not object.is_a?(mod)
            raise ModuleError, "Object doesn't include module -- #{mod.inspect}"
          end
        end

        def self.fixture_modules(object)
          fixture_modules = []

          targets = included_modules(object)

          targets << object

          targets.select do |target|
            if fixture_module?(target)
              fixture_module = fixture_module(target)
              fixture_modules << fixture_module
            end
          end

          fixture_modules
        end

        def self.fixture_module(object)
          if not fixture_module?(object)
            raise ModuleError, "Couldn't resolve a Fixture module -- #{object.inspect}"
          end

          target = fixture_module_target(object)

          target.const_get(:Fixture, false)
        end

        def self.fixture_module?(object)
          target = fixture_module_target(object)

          if not target.const_defined?(:Fixture, false)
            false
          elsif target.const_get(:Fixture) == Fixture
            false
          else
            true
          end
        end

        def self.fixture_module_target(object)
          if object.is_a?(Module)
            object
          else
            object.class
          end
        end

        def self.included_modules(object)
          modules = (object.class.included_modules | object.singleton_class.included_modules) - ::Object.included_modules
          modules.sort_by(&:name)
        end
      end
    end
  end
end

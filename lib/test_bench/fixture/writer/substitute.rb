module TestBench
  module Fixture
    class Writer
      module Substitute
        def self.build
          Writer.build
        end

        class Writer < Writer
          def self.build
            instance = new
            instance.buffer.limit = 0
            instance
          end

          def written_data
            device.written_data
          end
          alias :written_text :written_data

          def styling!
            self.styling_policy = Styling.on
          end
        end
      end
    end
  end
end

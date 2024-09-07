module TestBench
  module Fixture
    class Writer
      module Device
        class Null
          def self.build
            @instance ||= new
          end

          def write(data)
            data.bytesize
          end

          def tty?
            false
          end
        end
      end
    end
  end
end

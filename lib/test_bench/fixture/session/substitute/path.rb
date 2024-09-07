module TestBench
  module Fixture
    class Session
      module Substitute
        class Path
          def segments
            @segments ||= []
          end
          attr_writer :segments

          def match?(*segments, segment)
            if not segment == self.segments.last
              return false
            end

            segment_iterator = self.segments.to_enum

            control_segments = [*segments, segment]

            control_segments.all? do |control_segment|
              begin
                next_segment = segment_iterator.next
              end until next_segment == control_segment
              true

            rescue StopIteration
              false
            end
          end

          def push_segment(segment)
            segments << segment
          end
          alias :push :push_segment
          alias :<< :push

          def pop_segment(compare_segment=nil)
            segments.pop
          end
          alias :pop :pop_segment

          def copy(receiver)
            path = self.class.new

            segments.each do |segment|
              path << segment
            end

            receiver.path = path
            path
          end

          def eql?(compare)
            if compare.is_a?(self.class)
              segments == compare.segments
            else
              false
            end
          end
          alias :== :eql?
        end
      end
    end
  end
end

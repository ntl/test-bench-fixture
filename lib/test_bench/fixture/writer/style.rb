module TestBench
  module Fixture
    class Writer
      module Style
        Error = Class.new(RuntimeError)

        def self.control_code(style)
          control_codes.fetch(style) do
            raise Error, "Invalid style #{style.inspect}"
          end
        end

        def self.control_codes
          @sgr_codes ||= {
            :reset => '0',

            :bold => '1',
            :faint => '2',
            :italic => '3',
            :underline => '4',
            :reverse_video => '7',

            :reset_intensity => '22',
            :reset_italic => '23',
            :reset_underline => '24',
            :reset_reverse_video => '27',

            :black => '30',
            :red => '31',
            :green => '32',
            :yellow => '33',
            :blue => '34',
            :magenta => '35',
            :cyan => '36',
            :white => '37',
            :reset_fg => '39',

            :black_bg => '40',
            :red_bg => '41',
            :green_bg => '42',
            :yellow_bg => '43',
            :blue_bg => '44',
            :magenta_bg => '45',
            :cyan_bg => '46',
            :white_bg => '47',
            :reset_bg => '49'
          }
        end
      end
    end
  end
end

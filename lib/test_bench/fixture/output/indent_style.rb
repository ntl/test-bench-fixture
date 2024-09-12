module TestBench
  module Fixture
    class Output
      module IndentStyle
        Error = Class.new(RuntimeError)

        extend self

        def self.get(text, heading, indent_style=nil)
          assure_indent_style(indent_style, text, heading)
        end

        def self.assure_indent_style(indent_style, text=nil, heading=nil)
          text ||= ''

          case indent_style
          when *indent_styles
            indent_style
          when nil
            newline_terminated = text.match?(/\R\z/)

            if newline_terminated
              if heading.nil?
                unstyled
              else
                quote
              end
            else
              first_line
            end
          else
            raise Error, "Unknown indentation style #{indent_style.inspect}"
          end
        end

        def indent_styles
          [
            unstyled,
            first_line,
            quote,
            line_number,
            off
          ]
        end

        def unstyled
          :unstyled
        end

        def first_line
          :first_line
        end

        def quote
          :quote
        end

        def line_number
          :line_number
        end

        def off
          :off
        end
      end
    end
  end
end

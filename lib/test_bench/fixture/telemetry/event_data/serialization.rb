module TestBench
  module Fixture
    class Telemetry
      class EventData
        module Serialization
          Error = Class.new(RuntimeError)

          def self.dump(event_data)
            type = event_data.type.to_s
            process_id = dump_value(event_data.process_id)
            time = dump_value(event_data.time)
            data = event_data.data

            text = String.new(encoding: 'BINARY')

            text << type

            text << "\t"
            text << process_id

            text << "\t"
            text << time

            data.each do |value|
              text << "\t"
              text << dump_value(value)
            end

            text << "\r\n"
            text
          end

          def self.dump_value(value)
            case value
            when Integer
              value.to_s
            when Time
              value.strftime('%Y-%m-%dT%H:%M:%S.%NZ')
            when NilClass
              ''
            when TrueClass, FalseClass
              value.to_s
            when String
              value.dump
            end
          end

          def self.load(text)
            match_data = Pattern.match(text)
            if match_data.nil?
              raise Error, "Cannot deserialize #{text.inspect}"
            end

            type = match_data['type'].to_sym
            process_id = load_value(match_data['process_id'])
            time = load_value(match_data['time_attribute'])

            event_data = EventData.new
            event_data.type = type
            event_data.process_id = process_id
            event_data.time = time
            event_data.data = []

            data_text = match_data['data']

            data_text.insert(0, "\t")
            data_text.scan(/\t([^\t]*)/) do |(value_text)|
              value = load_value(value_text)
              event_data.data << value
            end

            event_data
          end

          def self.load_value(value_text)
            match_data = Pattern.match_value(value_text)

            if match_data['integer']
              Integer(value_text)
            elsif match_data['time']
              year = match_data['year'].to_i
              month = match_data['month'].to_i
              day = match_data['day'].to_i
              hour = match_data['hour'].to_i
              minute = match_data['minute'].to_i
              second = match_data['second'].to_i

              nanosecond = match_data['nanosecond'].to_i
              usec = Rational(nanosecond, 1_000)

              Time.utc(year, month, day, hour, minute, second, usec)
            elsif match_data['nil']
              nil
            elsif match_data['true']
              true
            elsif match_data['false']
              false
            elsif match_data['string']
              value_text.undump
            end
          end

          module Pattern
            def self.match(data)
              event_data.match(data)
            end

            def self.match_value(value_text)
              value_pattern.match(value_text)
            end

            def self.event_data
              @event_data ||= %r{\A#{type}\t#{process_id}\t#{time_attribute}\t#{data}\r\n\z}
            end

            def self.type
              %r{(?<type>[A-Z][[:alnum:]]+)}
            end

            def self.process_id
              %r{(?<process_id>#{integer})}
            end

            def self.value_pattern
              @value_pattern ||= %r{\A#{value}\z}
            end

            def self.time_attribute
              %r{(?<time_attribute>#{time})}
            end

            def self.data
              %r{(?<data>#{value}(?:\t#{value})*)}
            end

            def self.value
              %r{#{integer}|#{time}|#{self.nil}|#{boolean}|#{string}}
            end

            def self.integer
              %r{(?<integer>[[:digit:]]+)}
            end

            def self.time
              year = %r{(?<year>[[:digit:]]{4})}
              month = %r{(?<month>[[:digit:]]{2})}
              day = %r{(?<day>[[:digit:]]{2})}
              hour = %r{(?<hour>[[:digit:]]{2})}
              minute = %r{(?<minute>[[:digit:]]{2})}
              second = %r{(?<second>[[:digit:]]{2})}
              nanosecond = %r{(?<nanosecond>[[:digit:]]{9})}

              %r{(?<time>#{year}-#{month}-#{day}T#{hour}:#{minute}:#{second}\.#{nanosecond}Z)}
            end

            def self.nil
              %r{(?<nil>(?=[\t\r])?)}
            end

            def self.boolean
              %r{(?<true>true)|(?<false>false)}
            end

            def self.string
              %r{(?<string>".*")}
            end
          end
        end
      end
    end
  end
end

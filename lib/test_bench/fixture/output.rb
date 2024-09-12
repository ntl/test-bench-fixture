module TestBench
  module Fixture
    class Output
      include Telemetry::Sink::Handler
      include Events

      def pending_writer
        @pending_writer ||= Writer::Substitute.build
      end
      attr_writer :pending_writer

      def passing_writer
        @passing_writer ||= Writer::Substitute.build
      end
      attr_writer :passing_writer

      def failing_writer
        @failing_writer ||= Writer::Substitute.build
      end
      attr_writer :failing_writer

      def failures
        @failures ||= 0
      end
      attr_writer :failures

      def mode
        @mode ||= Mode.initial
      end
      attr_writer :mode

      def branch_count
        @branch_count ||= 0
      end
      attr_writer :branch_count

      def detail_policy
        @detail_policy ||= Output::Detail.default
      end
      alias :detail :detail_policy
      attr_writer :detail_policy

      def self.build(writer: nil, device: nil, styling: nil, detail: nil)
        instance = new

        if not detail.nil?
          instance.detail_policy = detail
        end

        Writer.configure(instance, writer:, device:, styling:, attr_name: :pending_writer)

        instance
      end

      def self.configure(receiver, attr_name: nil, writer: nil, device: nil, styling: nil, detail: nil)
        attr_name ||= :output

        instance = build(writer:, device:, styling:, detail:)
        receiver.public_send(:"#{attr_name}=", instance)
      end

      def self.register_telemetry(telemetry, writer: nil, device: nil, styling: nil, detail: nil)
        instance = build(writer:, device:, styling:, detail:)
        telemetry.register(instance)
        instance
      end
      singleton_class.alias_method :register, :register_telemetry

      def receive(event_data)
        case event_data.type
        when ContextStarted.event_type, TestStarted.event_type
          branch
        end

        if initial?
          handle(event_data)

        else
          self.mode = Mode.failing
          handle(event_data)

          self.mode = Mode.passing
          handle(event_data)

          self.mode = Mode.pending
          handle(event_data)
        end

        case event_data.type
        when ContextFinished.event_type, TestFinished.event_type
          _title, result = event_data.data
          merge(result)
        end
      end

      handle ContextStarted do |context_started|
        title = context_started.title

        if not title.nil?
          writer.
            indent.
            style(:green).
            puts(title)

          writer.indent!

          if branch_count == 1
            self.failures = 0
          end
        end
      end

      handle ContextFinished do |context_finished|
        title = context_finished.title

        if not title.nil?
          writer.deindent!

          if branch_count == 1
            writer.puts

            if failing? && failures > 0
              writer.
                style(:bold, :red).
                puts("Failure#{'s' if not failures == 1}: #{failures}")

              writer.puts
            end
          end
        end
      end

      handle ContextSkipped do |context_skipped|
        title = context_skipped.title

        if not writer.styling?
          title = "#{title} (skipped)"
        end

        writer.
          indent.
          style(:yellow).
          puts(title)
      end

      handle TestStarted do |test_started|
        title = test_started.title

        if title.nil?
          if passing?
            return
          else
            title = 'Test'
          end
        end

        writer.indent

        if passing?
          writer.style(:green)
        elsif failing?
          if not writer.styling?
            title = "#{title} (failed)"
          end

          writer.style(:bold, :red)
        elsif pending?
          writer.style(:faint)
        end

        writer.puts(title)

        writer.indent!
      end

      handle TestFinished do |test_finished|
        title = test_finished.title

        if passing? && title.nil?
          return
        end

        writer.deindent!
      end

      handle TestSkipped do |test_skipped|
        title = test_skipped.title

        if not writer.styling?
          title = "#{title} (skipped)"
        end

        writer.
          indent.
          style(:yellow).
          puts(title)
      end

      handle Failed do |failed|
        message = failed.message

        if failing?
          self.failures += 1
        end

        writer
          .indent
          .style(:red)
          .puts(message)
      end

      handle Detailed do |detailed|
        if not detail?
          return
        end

        text = detailed.text
        heading = detailed.heading
        indent_style = detailed.indent_style

        comment(text, heading, indent_style)
      end

      handle Commented do |commented|
        text = commented.text
        heading = commented.heading
        indent_style = commented.indent_style

        comment(text, heading, indent_style)
      end

      def comment(text, heading, indent_style)
        if not heading.nil?
          writer.
            indent.
            style(:bold, :underline).
            puts(heading)

          if not writer.styling?
            writer.
              indent.
              puts('- - -')
          end
        end

        if text.empty?
          writer.
            indent.
            style(:faint, :italic).
            puts('(empty)')
          return
        end

        indent_style = IndentStyle.get(text, heading, indent_style)

        text_lines = text.lines(chomp: true)

        case indent_style
        when IndentStyle.quote
          get_marker = proc { '> ' }
        when IndentStyle.line_number
          line_number_width = text_lines.count.to_s.length
          marker_width = line_number_width + 2

          get_marker = proc { |line_number|
            "#{line_number}.".ljust(marker_width)
          }

        else
          get_marker = proc { '' }
        end

        text_lines.each.with_index(1) do |text_line, line_number|
          if not indent_style == IndentStyle.off
            if line_number == 1 || indent_style != IndentStyle.first_line
              writer.indent
            end
          end

          marker = get_marker.(line_number)
          if not marker.empty?
            writer.
              style(:faint).
              print(marker).
              style(:reset_intensity)
          end

          writer.puts(text_line)
        end
      end

      def current_writer
        if initial? || pending?
          pending_writer
        elsif passing?
          passing_writer
        elsif failing?
          failing_writer
        end
      end
      alias :writer :current_writer

      def branch
        if branch_count.zero?
          self.mode = Mode.pending

          pending_writer.sync = false

          parent_writer = pending_writer
        else
          parent_writer = passing_writer
        end

        self.branch_count += 1

        self.passing_writer, self.failing_writer = parent_writer.branch
      end

      def merge(result)
        self.branch_count -= 1

        if not branched?
          pending_writer.sync = true

          self.mode = Mode.initial
        end

        if result
          writer = passing_writer
        else
          writer = failing_writer
        end

        writer.flush

        self.passing_writer = writer.device
        self.failing_writer = writer.alternate_device
      end

      def branched?
        branch_count > 0
      end

      def initial?
        mode == Mode.initial
      end

      def pending?
        mode == Mode.pending
      end

      def passing?
        mode == Mode.passing
      end

      def failing?
        mode == Mode.failing
      end

      def detail?
        Detail.detail?(detail_policy, mode)
      end

      def indent_style(text, heading, indent_style=nil)
        IndentStyle.get(text, heading, indent_style)
      end

      module Mode
        def self.initial
          :initial
        end

        def self.pending
          :pending
        end

        def self.passing
          :passing
        end

        def self.failing
          :failing
        end
      end

      module Substitute
        def self.build
          Output.new
        end

        class Output < Telemetry::Substitute::Sink
          def handle(event_or_event_data)
            if event_or_event_data.is_a?(Telemetry::Event)
              event_data = Telemetry::Event::Export.(event_or_event_data)
            else
              event_data = event_or_event_data
            end

            receive(event_data)
          end
        end
      end
    end
  end
end

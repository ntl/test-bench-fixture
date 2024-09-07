module TestBench
  module Fixture
    class Writer
      def device
        @device ||= Device::Substitute.build
      end
      attr_writer :device

      def alternate_device
        @alternate_device ||= Device::Substitute.build
      end
      attr_writer :alternate_device

      def styling_policy
        @styling_policy ||= Styling.default
      end
      alias :styling :styling_policy
      attr_writer :styling_policy

      def digest
        @digest ||= TestBench::Digest::Hash.new
      end
      attr_writer :digest

      def sequence
        @sequence ||= 0
      end
      attr_writer :sequence

      def buffer
        @buffer ||= Buffer.new
      end
      attr_writer :buffer

      def indentation_depth
        @indentation_depth ||= 0
      end
      attr_writer :indentation_depth

      attr_accessor :peer

      def configure
        self.alternate_device = Device::Null.build

        Buffer.configure(self)
      end

      def self.build(device=nil, styling: nil, inert_digest: nil)
        device ||= Defaults.device
        inert_digest = true if inert_digest.nil?

        instance = new
        instance.device = device
        instance.styling_policy = styling

        if inert_digest
          instance.digest = NullDigest.new
        end

        instance.configure

        instance
      end

      def self.configure(receiver, writer: nil, styling: nil, inert_digest: nil, device: nil, attr_name: nil)
        attr_name ||= :writer

        if not writer.nil?
          instance = writer
        else
          instance = build(device, styling:, inert_digest:)
        end

        receiver.public_send(:"#{attr_name}=", instance)
      end

      def self.follow(previous_writer)
        device = previous_writer

        alternate_device = previous_writer.peer
        alternate_device ||= Device::Null.build

        previous_digest = previous_writer.digest
        digest = previous_digest.clone

        writer = new
        writer.sync = false
        writer.device = device
        writer.alternate_device = alternate_device
        writer.styling_policy = previous_writer.styling_policy
        writer.digest = digest
        writer.sequence = previous_writer.sequence
        writer.indentation_depth = previous_writer.indentation_depth
        writer.digest = previous_writer.digest.clone
        writer
      end

      def sync
        @sync.nil? ? @sync = true : @sync
      end

      def tty
        @tty.nil? ? @tty = device_tty? : @tty
      end
      attr_writer :tty
      alias :tty? :tty

      def puts(text=nil)
        if not text.nil?
          text = text.chomp

          print(text)
        end

        style(:reset)

        if tty?
          write("\e[0K")
        end

        write("\n")
      end

      def style(style, *additional_styles)
        control_code = Style.control_code(style)
        control_codes = [control_code]

        additional_styles.each do |style|
          control_code = Style.control_code(style)
          control_codes << control_code
        end

        if styling?
          write("\e[#{control_codes.join(';')}m")
        end

        self
      end

      def print(text)
        write(text)

        self
      end

      def write(data)
        if sync
          bytes_written = write!(data)
        else
          bytes_written = buffer.receive(data)
        end

        self.sequence += bytes_written

        data = data[0...bytes_written]
        digest.update(data)

        bytes_written
      end

      def write!(data)
        device.write(data)

        alternate_device.write(data)

        data.bytesize
      end

      def branch
        alternate = self.class.follow(self)
        primary = self.class.follow(self)

        primary.peer = alternate

        return primary, alternate
      end

      def follows?(other_writer)
        if sequence < other_writer.sequence
          false
        elsif device == other_writer
          true
        elsif device == other_writer.peer
          true
        else
          false
        end
      end

      def increase_indentation
        self.indentation_depth += 1
      end
      alias :indent! :increase_indentation

      def decrease_indentation
        self.indentation_depth -= 1
      end
      alias :deindent! :decrease_indentation

      def indent
        indentation = '  ' * indentation_depth

        print(indentation)
      end

      def device_tty?
        device.tty?
      end

      def flush
        buffer.flush(device, alternate_device)
      end

      def sync=(sync)
        @sync = sync

        if sync
          flush
        end
      end

      def written?(data=nil)
        if data.nil?
          sequence > 0
        else
          digest.text?(data)
        end
      end

      def current?(sequence)
        sequence >= self.sequence
      end

      def styling?
        Styling.styling?(styling_policy, tty?)
      end

      class NullDigest
        def update(_data)
        end

        def text?(_data)
          false
        end
      end

      module Defaults
        def self.device
          STDOUT
        end
      end
    end
  end
end

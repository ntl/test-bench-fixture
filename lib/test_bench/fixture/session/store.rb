module TestBench
  module Fixture
    class Session
      class Store
        PutError = Class.new(RuntimeError)

        attr_accessor :put_session

        def self.configure(receiver, attr_name: nil)
          attr_name ||= :session_store

          receiver.public_send(:"#{attr_name}=", instance)
        end

        def self.instance
          @instance ||= new
        end

        def self.put(...) = instance.put(...)
        def self.put?(...) = instance.put?(...)
        def self.reset(...) = instance.reset(...)
        def self.get(...) = instance.get(...)
        def self.fetch(...) = instance.fetch(...)

        def put(session)
          if not put_session.nil?
            raise PutError, "Already put a session"
          end

          self.put_session = session
        end

        def put?(session=nil)
          if not session.nil?
            put_session == session
          else
            !put_session.nil?
          end
        end

        def reset(session=nil)
          self.put_session = session
        end

        def get
          put_session
        end

        def fetch
          self.put_session ||= new_session
        end

        def new_session
          Session.build do |telemetry|
            Output.register_telemetry(telemetry)
          end
        end
      end
    end
  end
end

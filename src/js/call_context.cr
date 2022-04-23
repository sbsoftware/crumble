module JS
  abstract class CallContext
    @receiver : String

    def initialize(@receiver = "")
    end

    def resolve_call(name, *args)
      "#{receiver_dot(name)}(#{args.join(", ")})"
    end

    def resolve_attr(name)
      receiver_dot(name)
    end

    def resolve_assignment(name, new_val)
      "#{receiver_dot(name)} = #{new_val}"
    end

    def forward(ctx_class, next_receiver)
      ctx_class.new(receiver_dot(next_receiver))
    end

    def forward_call(ctx_class, next_receiver, *args)
      ctx_class.new(resolve_call(next_receiver, *args))
    end

    def to_s(io : IO)
      io << @receiver
    end

    def inspect(io : IO)
      io << @receiver
    end

    def receiver_dot(call)
      @receiver.blank? ? call : "#{@receiver}.#{call}"
    end

    def js_object(args)
      String.build do |jso|
        jso << "{"
        args.to_h.join(jso, ", ") do |(key, val), _jso|
          _jso << "\""
          _jso << key
          _jso << "\""
          _jso << ": "
          case val
          when String
            _jso << "\""
            _jso << val
            _jso << "\""
          when Hash
            _jso << js_object(val)
          else
            _jso << val
          end
        end
        jso << "}"
      end
    end

    def rename(new_name)
      @receiver = new_name
      self
    end
  end
end

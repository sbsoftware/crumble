{% unless flag?(:release) %}
  require "./resource/resource"

  class LiveReloadResource < Crumble::Resource
    PROCESS_RUN_TIME = Time.utc

    def index
      ctx.response.content_type = "text/event-stream"
      ctx.response.headers["Cache-Control"] = "no-cache"
      ctx.response.headers["Connection"] = "keep-alive"
      ctx.response.headers["X-Accel-Buffering"] = "no"

      ctx.response.upgrade do |io|
        socket = io.as(TCPSocket)
        Socket.set_blocking(socket.fd, true)
        socket.sync = true

        loop do
          io << "data: "
          io << PROCESS_RUN_TIME
          io << "\n\n"

          sleep 1.minute
        end
      end
    end
  end
{% end %}

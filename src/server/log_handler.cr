require "http/server/handler"

class LogHandler
  include HTTP::Handler

  def initialize(@io : IO)
  end

  def call(context)
    @io << request_details(context.request) + " Started\n"
    duration = Time.measure do
      call_next(context)
    end
    @io << request_details(context.request) + " Completed #{context.response.status_code} (#{duration.total_seconds.humanize(precision: 2)}s)\n"
  end

  private def request_details(req)
    "{#{req.id}} [#{Time.local.to_s("%Y-%m-%d %H:%M:%S.%6N")}] #{remote_address(req)} #{req.method} #{req.resource}"
  end

  private def remote_address(req)
    req.headers["X-Forwarded-For"]? || req.remote_address
  end
end

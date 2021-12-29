require "http/server/handler"

class LogHandler
  include HTTP::Handler

  def call(ctx)
    puts request_details(ctx.request) + " Started"
    duration = Time.measure do
      call_next(ctx)
    end
    puts request_details(ctx.request) + " Completed #{ctx.response.status_code} (#{duration.total_seconds.humanize(precision: 2)}s)"
  end

  private def request_details(req)
    "{#{req.id}} [#{Time.local.to_s("%Y-%m-%d %H:%M:%S.%6N")}] #{req.remote_address} #{req.method} #{req.resource}"
  end
end

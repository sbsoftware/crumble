require "./test_request_context"
require "./test_view_handler"

macro test_handler_context(**args)
  %request_ctx = ::Crumble::Server::TestRequestContext.new({{args.double_splat}})
  ::Crumble::Server::HandlerContext.new(%request_ctx, TestViewHandler.new(%request_ctx))
end

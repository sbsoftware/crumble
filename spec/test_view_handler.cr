class TestViewHandler
  include Crumble::Server::ViewHandler

  def initialize(@request_ctx); end

  def self.handle(ctx) : Bool
    true
  end

  def window_title : String?
    nil
  end
end

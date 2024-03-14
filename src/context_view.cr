abstract class Crumble::ContextView
  getter ctx : Server::RequestContext

  def initialize(@ctx); end

  macro template(&blk)
    ToHtml.instance_template {{blk}}
  end
end

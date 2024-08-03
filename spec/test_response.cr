class Crumble::Server::TestResponse < HTTP::Server::Response
  def initialize(io : IO? = nil)
    super(io || IO::Memory.new)
  end
end

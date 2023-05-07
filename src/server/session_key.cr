require "uuid"

class Crumble::Server::SessionKey
  @id : UUID

  def initialize(@id)
  end

  def self.generate
    new(UUID.random)
  end

  def to_s(io : IO)
    io << @id
  end
end

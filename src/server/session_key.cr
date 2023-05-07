require "uuid"

class Crumble::Server::SessionKey
  getter id : UUID

  def initialize(@id)
  end

  def self.generate
    new(UUID.random)
  end

  def ==(other)
    self.id == other.id
  end

  def to_s(io : IO)
    io << @id
  end
end

require "uuid"
require "yaml"

class Crumble::Server::SessionKey
  include YAML::Serializable

  class UUIDConverter
    def self.from_yaml(ctx, node) : UUID
      unless node.is_a?(YAML::Nodes::Scalar)
        raise "Expected scalar, not #{node.kind}"
      end

      UUID.new(node.value)
    end

    def self.to_yaml(value : UUID, builder : YAML::Nodes::Builder) : Nil
      builder.scalar value.to_s
    end
  end

  @[YAML::Field(converter: Crumble::Server::SessionKey::UUIDConverter)]
  getter id : UUID

  delegate :hash, to: id

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

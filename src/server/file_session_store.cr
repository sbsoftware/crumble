require "./session_store"

class Crumble::Server::FileSessionStore
  include SessionStore

  @folder : Path

  def initialize(folder : String)
    @folder = Path.new(folder).normalize.to_native
  end

  def has_key?(key : SessionKey) : Bool
    File.exists?(path(key))
  end

  def [](key : SessionKey) : Session
    File.open(path(key)) do |io|
      Session.from_yaml(io)
    end
  end

  private def store(session : Session) : Nil
    File.open(path(session.id), "w") do |io|
      session.to_yaml(io)
    end
  end

  private def path(key : SessionKey)
    @folder / key.to_s
  end
end

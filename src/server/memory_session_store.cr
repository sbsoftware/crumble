require "./session_store"

class Crumble::Server::MemorySessionStore
  include SessionStore

  @store : Hash(SessionKey, Crumble::Server::Session)

  def initialize
    @store = {} of SessionKey => Crumble::Server::Session
  end

  def has_key?(key : SessionKey) : Bool
    @store.has_key?(key)
  end

  def [](key : SessionKey) : Crumble::Server::Session
    @store[key]
  end

  private def store(session : Crumble::Server::Session) : Nil
    @store[session.id] = session
  end
end

require "./session_store"

class Crumble::Server::MemorySessionStore(S)
  include SessionStore(S)

  @store : Hash(SessionKey, S)

  def initialize
    @store = {} of SessionKey => S
  end

  def has_key?(key : SessionKey) : Bool
    @store.has_key?(key)
  end

  def [](key : SessionKey) : S
    @store[key]
  end

  def set(session : S) : Nil
    @store[session.id] = session
  end
end

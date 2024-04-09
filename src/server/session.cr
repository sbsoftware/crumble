require "./session_store"

class Crumble::Server::Session
  getter id : SessionKey
  private getter session_store : SessionStore

  def initialize(@session_store, @id)
  end
end

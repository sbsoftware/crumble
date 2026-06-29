require "./session"
require "./session_store"

class Crumble::Server::SessionDecorator
  getter session_store : SessionStore
  getter session : Session

  forward_missing_to session

  def initialize(@session_store, @session); end

  def update!(**args)
    session.update!(**args)

    session_store.set(session)
  end

  # Replaces the wrapped session with the latest version from the store and returns this decorator.
  # This keeps the current session id; if the store no longer has that session, the store lookup raises.
  def reload
    @session = session_store[session.id]

    self
  end
end

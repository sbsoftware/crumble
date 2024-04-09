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
end

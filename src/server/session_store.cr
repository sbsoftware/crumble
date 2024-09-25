require "./session_key"

module Crumble::Server::SessionStore
  abstract def has_key?(key : SessionKey) : Bool
  abstract def [](key : SessionKey) : Crumble::Server::Session
  private abstract def store(session : Crumble::Server::Session) : Nil

  def set(session : Crumble::Server::Session) : Nil
    if session.responds_to? :created_at=
      unless session.created_at
        session.created_at = Time.utc
      end
    end
    if session.responds_to? :updated_at=
      session.updated_at = Time.utc
    end

    store(session)
  end
end

require "./session_key"

module Crumble::Server::SessionStore
  abstract def has_key?(key : SessionKey) : Bool
  abstract def [](key : SessionKey) : Crumble::Server::Session
  abstract def set(session : Crumble::Server::Session) : Nil
end

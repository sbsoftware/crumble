module Crumble::Server::SessionStore(S)
  abstract def has_key?(key : SessionKey) : Bool
  abstract def [](key : SessionKey) : S
  abstract def set(session : S) : Nil
end

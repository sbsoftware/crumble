module Crumble::Server::SessionStore(S)
  abstract def get(key : SessionKey) : S
  abstract def set(session : S) : Nil
end

abstract class Crumble::Server::AbstractRequestContext
  abstract def request
  abstract def response
  abstract def session
end

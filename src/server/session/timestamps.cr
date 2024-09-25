class Crumble::Server::Session
  # Defines `#created_at` and `#updated_at` properties.
  # These will be automatically filled by the session store when calling `#set`.
  # Include this module in your project's `Crumble::Server::Session` class for convenience.
  module Timestamps
    macro included
      property created_at : Time?
      property updated_at : Time?
    end
  end
end

require "crumble/welcome_view"

class RootResource < ApplicationResource
  def self.root_path
    "/"
  end

  def index
    render Crumble::WelcomeView
  end
end

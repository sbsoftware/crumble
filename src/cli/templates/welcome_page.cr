class WelcomePage < ApplicationPage
  root_path "/"

  view do
    template do
      h1 { "Welcome to the Crumble framework!" }
    end
  end
end

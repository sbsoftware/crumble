class WelcomePage < ApplicationPage
  root_path "/"

  view do
    ToHtml.class_template do
      h1 { "Welcome to the Crumble framework!" }
    end
  end
end

class WelcomePage < ApplicationPage
  def self.root_path
    "/"
  end

  view do
    ToHtml.class_template do
      h1 { "Welcome to the Crumble framework!" }
    end
  end
end

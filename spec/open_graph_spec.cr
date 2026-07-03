require "./spec_helper"

module Crumble::OpenGraphSpec
  class OpenGraphPage < Crumble::Page
    template do
      div { "Open Graph" }
    end

    layout ToHtml::Layout

    def og_title : String?
      "Invite title"
    end

    def og_description : String?
      "Short description"
    end

    def og_audio : String?
      "https://example.com/theme.mp3"
    end

    def og_audio_secure_url : String?
      "https://secure.example.com/theme.mp3"
    end

    def og_audio_type : String?
      "audio/mpeg"
    end

    def meta_description : String?
      "Join the room and chat in real time."
    end

    def og_determiner : String?
      "the"
    end

    def og_image : String?
      "https://example.com/preview.png"
    end

    def og_image_url : String?
      "https://example.com/preview.png"
    end

    def og_image_secure_url : String?
      "https://secure.example.com/preview.png"
    end

    def og_image_type : String?
      "image/png"
    end

    def og_image_width : String?
      "1200"
    end

    def og_image_height : String?
      "630"
    end

    def og_image_alt : String?
      "Two people chatting in a web app"
    end

    def og_url : String?
      "https://example.com/invite"
    end

    def og_type : String?
      "website"
    end

    def og_locale : String?
      "en_US"
    end

    def og_locale_alternate : Array(String)?
      ["de_DE", "fr_FR"]
    end

    def og_site_name : String?
      "Example"
    end

    def og_video : String?
      "https://example.com/trailer.mp4"
    end

    def og_video_secure_url : String?
      "https://secure.example.com/trailer.mp4"
    end

    def og_video_type : String?
      "video/mp4"
    end

    def og_video_width : String?
      "1280"
    end

    def og_video_height : String?
      "720"
    end

    def og_video_alt : String?
      "A short product trailer"
    end

    def twitter_card : String?
      "summary_large_image"
    end

    def twitter_title : String?
      "Invite title"
    end

    def twitter_description : String?
      "Short description"
    end

    def twitter_image : String?
      "https://example.com/preview.png"
    end

    def twitter_image_alt : String?
      "Two people chatting in a web app"
    end
  end

  class DefaultOpenGraphPage < Crumble::Page
    template do
      div { "Default" }
    end

    layout ToHtml::Layout
  end
end

describe "OpenGraph meta tags" do
  it "renders provided OpenGraph and SEO tags in the layout head" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::OpenGraphSpec::OpenGraphPage.uri_path)
      Crumble::OpenGraphSpec::OpenGraphPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should contain("<meta name=\"description\" content=\"Join the room and chat in real time.\">")
    res.should contain("<meta property=\"og:title\" content=\"Invite title\">")
    res.should contain("<meta property=\"og:description\" content=\"Short description\">")
    res.should contain("<meta property=\"og:audio\" content=\"https://example.com/theme.mp3\">")
    res.should contain("<meta property=\"og:audio:secure_url\" content=\"https://secure.example.com/theme.mp3\">")
    res.should contain("<meta property=\"og:audio:type\" content=\"audio/mpeg\">")
    res.should contain("<meta property=\"og:determiner\" content=\"the\">")
    res.should contain("<meta property=\"og:image\" content=\"https://example.com/preview.png\">")
    res.should contain("<meta property=\"og:image:url\" content=\"https://example.com/preview.png\">")
    res.should contain("<meta property=\"og:image:secure_url\" content=\"https://secure.example.com/preview.png\">")
    res.should contain("<meta property=\"og:image:type\" content=\"image/png\">")
    res.should contain("<meta property=\"og:image:width\" content=\"1200\">")
    res.should contain("<meta property=\"og:image:height\" content=\"630\">")
    res.should contain("<meta property=\"og:image:alt\" content=\"Two people chatting in a web app\">")
    res.should contain("<meta property=\"og:url\" content=\"https://example.com/invite\">")
    res.should contain("<meta property=\"og:type\" content=\"website\">")
    res.should contain("<meta property=\"og:locale\" content=\"en_US\">")
    res.should contain("<meta property=\"og:locale:alternate\" content=\"de_DE\">")
    res.should contain("<meta property=\"og:locale:alternate\" content=\"fr_FR\">")
    res.should contain("<meta property=\"og:site_name\" content=\"Example\">")
    res.should contain("<meta property=\"og:video\" content=\"https://example.com/trailer.mp4\">")
    res.should contain("<meta property=\"og:video:secure_url\" content=\"https://secure.example.com/trailer.mp4\">")
    res.should contain("<meta property=\"og:video:type\" content=\"video/mp4\">")
    res.should contain("<meta property=\"og:video:width\" content=\"1280\">")
    res.should contain("<meta property=\"og:video:height\" content=\"720\">")
    res.should contain("<meta property=\"og:video:alt\" content=\"A short product trailer\">")
    res.should contain("<meta name=\"twitter:card\" content=\"summary_large_image\">")
    res.should contain("<meta name=\"twitter:title\" content=\"Invite title\">")
    res.should contain("<meta name=\"twitter:description\" content=\"Short description\">")
    res.should contain("<meta name=\"twitter:image\" content=\"https://example.com/preview.png\">")
    res.should contain("<meta name=\"twitter:image:alt\" content=\"Two people chatting in a web app\">")
  end

  it "omits OpenGraph and SEO tags when none are provided" do
    res = String.build do |io|
      ctx = Crumble::Server::TestRequestContext.new(response_io: io, resource: Crumble::OpenGraphSpec::DefaultOpenGraphPage.uri_path)
      Crumble::OpenGraphSpec::DefaultOpenGraphPage.handle(ctx).should eq(true)
      ctx.response.flush
    end

    res.should_not contain("name=\"description\"")
    res.should_not contain("property=\"og:")
    res.should_not contain("name=\"twitter:")
  end
end

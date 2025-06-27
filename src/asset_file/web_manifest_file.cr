require "./asset_file"

class WebManifestFile < AssetFile
  def initialize(contents)
    super("/manifest.webmanifest", contents)
  end

  def mime_type
    "application/manifest+json"
  end
end

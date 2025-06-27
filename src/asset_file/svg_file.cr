require "./asset_file"

class SVGFile < AssetFile
  def mime_type
    "image/svg+xml"
  end
end

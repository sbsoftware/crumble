require "./asset_file"

class SvgImage < AssetFile
  def mime_type
    "image/svg+xml"
  end
end

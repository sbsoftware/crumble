require "./asset_file"

class CssFile < AssetFile
  def mime_type
    "text/css"
  end
end

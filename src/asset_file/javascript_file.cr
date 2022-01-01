require "./asset_file"

class JavascriptFile < AssetFile
  def mime_type
    "application/javascript"
  end
end

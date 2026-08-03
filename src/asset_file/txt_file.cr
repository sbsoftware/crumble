require "./asset_file"

class TxtFile < AssetFile
  def mime_type
    "text/plain"
  end
end

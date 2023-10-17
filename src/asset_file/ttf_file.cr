require "./asset_file"

class TTFFile < AssetFile
  def mime_type
    "font/ttf"
  end
end

module AssetFileRegistry
  extend self

  @@asset_files = {} of String => AssetFile

  def add(path, asset_file)
    @@asset_files[path] = asset_file
  end

  def query(path)
    @@asset_files[path]?
  end
end

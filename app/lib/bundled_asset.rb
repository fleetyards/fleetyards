# frozen_string_literal: true

# An image Vite bundles from app/frontend, as a file on this machine. The
# release image deletes app/frontend, so there the file is the built copy the
# Vite manifest names, and the source path alone finds nothing.
module BundledAsset
  def self.file(path)
    source = source_root.join(path)
    return source if source.file?

    built = Rails.public_path.join(ViteRuby.instance.manifest.path_for(path).delete_prefix("/"))
    built if built.file?
  rescue ViteRuby::MissingEntrypointError
    nil
  end

  def self.source_root
    Rails.root.join(ViteRuby.config.source_code_dir)
  end
end

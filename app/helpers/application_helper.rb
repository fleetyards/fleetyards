# frozen_string_literal: true

module ApplicationHelper
  def title
    @title ? "#{@title} | #{I18n.t(:"title.default")}" : I18n.t(:"title.default")
  end

  def admin_title
    @title ? "#{@title} | #{I18n.t(:"title.default_admin")}" : I18n.t(:"title.default_admin")
  end

  def description
    @description || I18n.t(:"meta.description")
  end

  def keywords
    @keywords || I18n.t(:"meta.keywords")
  end

  def og_title
    title
  end

  def og_type
    @og_type || "website"
  end

  def og_url
    @og_url || request.original_url
  end

  def og_image
    @og_image || vite_asset_url("images/favicons/icon-512.png")
  end

  def og_description
    description
  end

  def api_url(path)
    "#{API_ENDPOINT}#{path.gsub(%r{v\d{1}/}, "")}"
  end

  def app_enabled?
    @app_enabled || false
  end

  def manifest_digest
    @manifest_digest ||= Digest::SHA1.hexdigest(ApplicationController.new.view_context.render("frontend/manifest", formats: [:json])).first(8)
  end

  def admin_manifest_digest
    @admin_manifest_digest ||= Digest::SHA1.hexdigest(ApplicationController.new.view_context.render("admin/manifest", formats: [:json])).first(8)
  end
end

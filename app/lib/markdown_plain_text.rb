# frozen_string_literal: true

require "redcarpet/render_strip"

# User-written descriptions are markdown, and some places they go -- a calendar
# entry -- only show plain text. Redcarpet strips the markup; what it leaves of
# the editor's own output (entities for & < >, the :::center fences) is undone
# here, so the text reads as the page shows it.
module MarkdownPlainText
  FENCE = /^:::(?:center)?[ \t]*$\n?/

  def self.render(text)
    return "" if text.blank?

    stripped = renderer.render(text)
    CGI.unescapeHTML(stripped.gsub(FENCE, "")).gsub(/\n{3,}/, "\n\n").strip
  end

  def self.renderer
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
  end
  private_class_method :renderer
end

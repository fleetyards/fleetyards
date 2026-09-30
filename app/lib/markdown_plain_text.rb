# frozen_string_literal: true

require "redcarpet/render_strip"

# User-written descriptions are markdown, and some places they go -- a calendar
# entry -- only show plain text. Redcarpet strips the markup; what it leaves of
# the editor's own output (entities for & < >, the :::center fences) is undone
# here, so the text reads as the page shows it.
module MarkdownPlainText
  FENCE = /^:::(?:center)?[ \t]*$\n?/

  # A catalogue item named inline, `[*Name*]` or `[*type:Name*]`, reads as its
  # name. The same grammar as the frontend's: no `*`, `]` or line break inside.
  CATALOGUE_TOKEN = /\[\*(?:(?:component|equipment|commodity|ship|blueprint|mission):)?([^*\]\n]+?)\*\]/i

  # An image's size, `![a](src){width=50%}`, is layout -- not words. The
  # renderer's shapes: a description may hold one level of brackets or an
  # escaped one, and only these widths are sizes -- any other stays as text.
  IMAGE_SIZE = /(!\[(?:[^\[\]\\]|\\.|\[[^\[\]]*\])*\]\([^)\s]+\))\{width=(?:25|50|75)%\}/

  CODE_FENCE = /\A {0,3}(`{3,}|~{3,})/
  CODE_SPAN = /(`[^`]+`)/

  def self.render(text)
    return "" if text.blank?

    prose = outside_code(text) do |part|
      part.gsub(IMAGE_SIZE, "\\1").gsub(CATALOGUE_TOKEN) { Regexp.last_match(1).strip }
    end

    stripped = renderer.render(prose)
    CGI.unescapeHTML(stripped.gsub(FENCE, "")).gsub(/\n{3,}/, "\n\n").strip
  end

  # Applies the block to the prose only: code -- fenced blocks and inline spans
  # -- shows a token or a size as written, as the page does.
  def self.outside_code(text)
    fence = nil

    text.each_line.map do |line|
      if fence
        fence = nil if line.strip.start_with?(fence) && line.strip.delete(fence[0]).empty?
        next line
      end

      if (open = CODE_FENCE.match(line))
        fence = open[1]
        next line
      end

      line.split(CODE_SPAN).each_with_index.map { |part, index| index.odd? ? part : yield(part) }.join
    end.join
  end
  private_class_method :outside_code

  def self.renderer
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
  end
  private_class_method :renderer
end

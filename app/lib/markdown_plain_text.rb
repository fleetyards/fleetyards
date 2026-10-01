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

      code_spans(line).map { |part, code| code ? part : yield(part) }.join
    end.join
  end
  private_class_method :outside_code

  # The frontend's split: a backtick opens a span only when it is not escaped,
  # so `\`` is prose.
  def self.code_spans(line)
    parts = []
    text = +""
    index = 0

    while index < line.length
      char = line[index]

      if char == "\\" && index + 1 < line.length
        text << line[index, 2]
        index += 2
        next
      end

      if char == "`" && (close = line.index("`", index + 1)) && close > index + 1
        parts << [text, false] unless text.empty?
        parts << [line[index..close], true]
        text = +""
        index = close + 1
        next
      end

      text << char
      index += 1
    end

    parts << [text, false] unless text.empty?
    parts
  end
  private_class_method :code_spans

  def self.renderer
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
  end
  private_class_method :renderer
end

# frozen_string_literal: true

module MarkdownHelper
  # The app renders notification bodies as markdown, so a mail carrying the same
  # body has to as well -- otherwise the one reader who chose e-mail is the one
  # who sees the asterisks.
  #
  # `filter_html` and `safe_links_only` rather than trust in the author: the
  # body reaches a mail client, which is the one place a stray <script> or a
  # javascript: href is worth nothing to us and something to an attacker.
  MARKDOWN_EXTENSIONS = {
    autolink: true,
    strikethrough: true,
    no_intra_emphasis: true
  }.freeze

  MARKDOWN_RENDER_OPTIONS = {
    filter_html: true,
    no_images: true,
    no_styles: true,
    safe_links_only: true,
    hard_wrap: true
  }.freeze

  def render_markdown(text)
    return "" if text.blank?

    markdown_renderer.render(text).html_safe # rubocop:disable Rails/OutputSafety
  end

  private def markdown_renderer
    @markdown_renderer ||= Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(MARKDOWN_RENDER_OPTIONS),
      MARKDOWN_EXTENSIONS
    )
  end
end

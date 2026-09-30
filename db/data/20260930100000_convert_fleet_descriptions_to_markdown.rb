# frozen_string_literal: true

# The fleet page used to hand the description to v-html, so some fleets wrote
# HTML into it. It renders as markdown now, escaped, and those tags would show
# up as text -- so they are rewritten into the markdown that means the same.
# <center> becomes a `:::center` block; <u>, which markdown has no word for,
# keeps its text and loses the tag.
#
# Only descriptions holding a tag are touched: `<< DAKKAR >>` or an arrow like
# `<-----` is text and already reads the same either way.
class ConvertFleetDescriptionsToMarkdown < ActiveRecord::Migration[8.1]
  TAG = %r{</?[a-z][a-z0-9]*[\s/>]}i

  # The same policy as the renderer's safeHref/safeSrc: http(s), or a path on
  # this origin -- `//host` and `/\host` are another one.
  SAME_ORIGIN_PATH = %r{\A/(?![/\\])}

  def up
    Fleet.where("description ~* ?", TAG.source).find_each do |fleet|
      next unless fleet.description.match?(TAG)

      fleet.update_columns(description: to_markdown(fleet.description), updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def to_markdown(html)
    render(Nokogiri::HTML5.fragment(html))
      .gsub(/[ \t]+$/, "")
      .gsub(/\n{3,}/, "\n\n")
      .strip
  end

  private

  def render(node)
    node.children.map { |child| render_node(child) }.join
  end

  def render_node(node)
    return node.text if node.text?
    return "" unless node.element?

    case node.name
    when "script", "style" then ""
    when "br" then "\n"
    when "b", "strong" then emphasise(render(node), "**")
    when "i", "em" then emphasise(render(node), "*")
    when "a" then link(node)
    when "img" then image(node)
    when "ul", "ol" then list(node)
    when "center" then "\n\n:::center\n#{render(node).strip}\n:::\n\n"
    when "p", "div" then "\n\n#{render(node).strip}\n\n"
    when /\Ah([1-6])\z/ then "\n\n#{"#" * [Regexp.last_match(1).to_i - 2, 1].max} #{render(node).strip}\n\n"
    else render(node)
    end
  end

  # Markdown emphasis cannot open or close on a space, so `<b>text </b>` keeps
  # its space outside the markers. The renderer reads one line at a time, so
  # emphasis spanning lines is closed and reopened on each of them.
  def emphasise(inner, marker)
    inner.split("\n", -1).map do |line|
      next line if line.strip.empty?

      "#{line[/\A\s*/]}#{marker}#{line.strip}#{marker}#{line[/\s*\z/]}"
    end.join("\n")
  end

  def link(node)
    inner = render(node)
    href = markdown_url(node["href"])
    return inner if inner.strip.empty? || inner.include?("](")
    return inner unless href.match?(%r{\Ahttps?://}) || href.match?(SAME_ORIGIN_PATH)

    "[#{inner.strip.gsub(/\s*\n\s*/, " ")}](#{href})"
  end

  def image(node)
    src = markdown_url(node["src"])
    return "" unless src.start_with?("https://") || src.match?(SAME_ORIGIN_PATH)

    "![#{node["alt"].to_s.gsub(/[\[\]\n]/, " ").squish}](#{src})"
  end

  # A markdown destination ends at the first `)` or space, so both are encoded.
  def markdown_url(url)
    url.to_s.strip.gsub("(", "%28").gsub(")", "%29").gsub(" ", "%20")
  end

  def list(node)
    items = node.element_children.select { |child| child.name == "li" }.map do |item|
      "- #{render(item).strip.gsub(/\s*\n\s*/, " ")}"
    end

    "\n\n#{items.join("\n")}\n\n"
  end
end

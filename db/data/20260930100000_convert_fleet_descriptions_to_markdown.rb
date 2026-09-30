# frozen_string_literal: true

# The fleet page used to hand the description to v-html, so some fleets wrote
# HTML into it. It renders as markdown now, escaped, and those tags would show
# up as text -- so they are rewritten into the markdown that means the same.
# <center> becomes a `::: center` block; <u>, which markdown has no word for,
# keeps its text and loses the tag.
#
# Only descriptions holding a tag are touched: `<< DAKKAR >>` or an arrow like
# `<-----` is text and already reads the same either way.
class ConvertFleetDescriptionsToMarkdown < ActiveRecord::Migration[8.1]
  TAG = %r{</?[a-z][a-z0-9]*[\s/>]}i

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
    when "center" then "\n\n::: center\n#{render(node).strip}\n:::\n\n"
    when "p", "div" then "\n\n#{render(node).strip}\n\n"
    when /\Ah([1-6])\z/ then "\n\n#{"#" * [Regexp.last_match(1).to_i - 2, 1].max} #{render(node).strip}\n\n"
    else render(node)
    end
  end

  # Markdown emphasis cannot open or close on a space, so `<b>text </b>` keeps
  # its space outside the markers.
  def emphasise(inner, marker)
    return inner if inner.strip.empty?

    leading = inner[/\A\s*/]
    trailing = inner[/\s*\z/]
    "#{leading}#{marker}#{inner.strip}#{marker}#{trailing}"
  end

  def link(node)
    inner = render(node)
    href = node["href"].to_s.strip
    return inner if inner.strip.empty? || !href.match?(%r{\Ahttps?://}) || inner.include?("](")

    "[#{inner.strip}](#{href})"
  end

  def image(node)
    src = node["src"].to_s.strip
    return "" unless src.start_with?("https://")

    "![#{node["alt"].to_s.strip}](#{src})"
  end

  def list(node)
    items = node.element_children.select { |child| child.name == "li" }.map do |item|
      "- #{render(item).strip.gsub(/\s*\n\s*/, " ")}"
    end

    "\n\n#{items.join("\n")}\n\n"
  end
end

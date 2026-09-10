# frozen_string_literal: true

require "test_helper"

# MailerTheme restates the app's design tokens as opaque hex, because no mail
# client resolves var() or composites alpha. A restatement drifts, so this
# recomputes every value from the theme file itself and fails when the two
# disagree - in either direction.
class MailerThemeTest < ActiveSupport::TestCase
  THEME_FILE = Rails.root.join("app/frontend/entrypoints/tailwind.css")
  THEME_LAYER = Rails.root.join("app/frontend/stylesheets/shared/themes.scss")

  # --color-<name>: <value>, ignoring the var() aliases (the mission categories).
  DECLARATION = /^\s*--color-([a-z0-9-]+):\s*(#[0-9a-f]{3,6}|rgb\([^)]*\))\s*;/i

  # Token -> the MailerTheme constant that must equal it.
  MIRRORED = {
    "background" => :BACKGROUND,
    "surface" => :SURFACE,
    "control" => :CONTROL,
    "control-hover" => :CONTROL_HOVER,
    "edge" => :EDGE,
    "edge-soft" => :EDGE_SOFT,
    "edge-faint" => :EDGE_FAINT,
    "text" => :TEXT,
    "lifted" => :LIFTED,
    "muted" => :MUTED,
    "endcap" => :ENDCAP,
    "primary" => :PRIMARY,
    "danger" => :DANGER,
    "warning" => :WARNING,
    "success" => :SUCCESS,
    "gold" => :GOLD
  }.freeze

  RADII = {
    "surface" => :RADIUS_SURFACE,
    "control" => :RADIUS_CONTROL
  }.freeze

  setup do
    @theme = parse_colors(THEME_FILE.read)
  end

  test "every mirrored token still exists in the theme file" do
    missing = MIRRORED.keys - @theme.keys
    assert_empty missing,
      "MailerTheme mirrors tokens that tailwind.css no longer declares: #{missing.join(", ")}. " \
      "Either the token was renamed or the mail no longer has a value to use."
  end

  test "mirrored colours equal the theme's, with alpha composited" do
    MIRRORED.each do |token, constant|
      expected = flatten(token)
      actual = MailerTheme.const_get(constant).downcase

      assert_equal expected, actual,
        "MailerTheme::#{constant} is #{actual} but --color-#{token} " \
        "(#{@theme[token]}) resolves to #{expected}. Update the constant."
    end
  end

  test "radii equal the theme's" do
    RADII.each do |token, constant|
      declared = THEME_FILE.read[/^\s*--radius-#{Regexp.escape(token)}:\s*([^;]+);/i, 1]&.strip

      assert_equal declared, MailerTheme.const_get(constant),
        "MailerTheme::#{constant} disagrees with --radius-#{token}."
    end
  end

  # The button cap steps one below the panel's and its radius is held to half its
  # own height - the ratio :root spells out in --cap-h-btn / --cap-r-btn. If the
  # panel cap is ever retuned, these have to move with it.
  test "button cap geometry stays derived from the panel cap" do
    panel_h = MailerTheme::CAP_HEIGHT.to_i
    assert_equal [panel_h - 2, 2].max, MailerTheme::CAP_HEIGHT_BTN.to_i,
      "--cap-h-btn is max(2px, --cap-h - 2px)"
    assert_equal [MailerTheme::CAP_HEIGHT_BTN.to_i / 2, 1].max, MailerTheme::CAP_RADIUS_BTN.to_i,
      "--cap-r-btn is held to half the button cap's own height"
  end

  # A theme is a set of custom properties on the frontend, and no mail client
  # resolves one - so ACCENTS restates the accent each theme declares, with the
  # same risk of drift the colours above have and the same answer to it.
  test "each themed accent equals that theme's --color-primary" do
    css = THEME_LAYER.read

    MailerTheme::ACCENTS.each do |theme, accent|
      block = css[/\[data-theme=["']#{Regexp.escape(theme.to_s)}["']\]\s*\{(.*?)\}/m, 1]
      assert block,
        "themes.scss declares no [data-theme=\"#{theme}\"] block, but MailerTheme::ACCENTS " \
        "has an accent for it. Either the theme was renamed or it no longer exists."

      declared = block[/^\s*--color-primary:\s*(#[0-9a-f]{3,6})\s*;/i, 1]
      assert declared, "[data-theme=\"#{theme}\"] declares no --color-primary"

      assert_equal normalize_hex(declared), accent.downcase,
        "MailerTheme::ACCENTS[#{theme.inspect}] is #{accent} but themes.scss declares " \
        "#{declared} for that theme. Update the constant."
    end
  end

  test "a mail that names no theme gets the default accent" do
    assert_equal MailerTheme::PRIMARY, MailerTheme.accent(nil)
  end

  # Silently rendering the frontend blue is the failure this indirection exists
  # to prevent, so a name nobody declared has to be loud.
  test "an unknown theme raises rather than falling back" do
    error = assert_raises(ArgumentError) { MailerTheme.accent(:nope) }
    assert_match(/unknown mail theme :nope/, error.message)
  end

  # The flooded tones are the one pair with no --color-* to mirror: Btn writes
  # their hovered cap as a literal rgb(255 255 255 / .65) over the flood. Same
  # contract as the mirrored colours - the constant is the composite - so it is
  # checked the same way, against the tone the app floods with.
  test "the flooded hover caps are white at .65 over their own tone" do
    {
      "danger" => :DANGER_CAP_HOVER,
      "warning" => :WARNING_CAP_HOVER
    }.each do |token, constant|
      base = rgb(flatten(token))
      expected = hex(base.map { |c| 255 * 0.65 + (c * 0.35) })

      assert_equal expected, MailerTheme.const_get(constant).downcase,
        "MailerTheme::#{constant} must be rgb(255 255 255 / .65) composited over " \
        "--color-#{token} (#{@theme[token]}), which is #{expected}."
    end
  end

  test "the two cap insets leave exactly the cap width between them" do
    inset = MailerTheme::CAP_INSET.to_i
    assert_equal 100 - (inset * 2), MailerTheme::CAP_WIDTH.to_i,
      "CAP_WIDTH must be what is left of 100% after an inset on each side"
  end

  private

  def parse_colors(css)
    css.scan(DECLARATION).to_h { |name, value| [name, value.strip] }
  end

  # Composites a token against the surface MailerTheme::BASES says it is drawn
  # on, and returns the opaque hex.
  def flatten(token)
    value = @theme.fetch(token)
    return normalize_hex(value) unless value.start_with?("rgb")

    r, g, b, alpha = value.match(/rgb\(\s*(\d+)\s+(\d+)\s+(\d+)\s*\/\s*([\d.]+)\s*\)/)
      &.captures&.map(&:to_f) || flunk("cannot parse --color-#{token}: #{value}")

    base = base_rgb_for(token)
    hex([r, g, b].each_with_index.map { |c, i| (c * alpha) + (base[i] * (1 - alpha)) })
  end

  def base_rgb_for(token)
    case MailerTheme::BASES.fetch(token) { flunk("MailerTheme::BASES has no base for #{token}") }
    when :background then rgb(normalize_hex(@theme.fetch("background")))
    when :surface then rgb(flatten("surface"))
    end
  end

  def normalize_hex(value)
    digits = value.delete_prefix("#")
    digits = digits.chars.flat_map { |c| [c, c] }.join if digits.length == 3
    "##{digits.downcase}"
  end

  def rgb(hex)
    hex.delete_prefix("#").scan(/../).map { |pair| pair.to_i(16) }
  end

  def hex(channels)
    "##{channels.map { |c| format("%02x", c.round) }.join}"
  end
end

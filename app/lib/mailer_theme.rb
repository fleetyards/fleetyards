# frozen_string_literal: true

# The app's design tokens, expressed for email.
#
# Every value here mirrors one in the @theme block of
# app/frontend/entrypoints/tailwind.css. Two things have to change on the way:
#
# 1. Alpha is resolved. A mail client composites nothing for us, so a token like
#    --color-surface rgb(39 43 48 / .9) has to arrive as the hex it becomes over
#    the surface it is actually drawn on. BASES below records which surface that
#    is for each token, and MailerThemeTest recomputes every value from
#    tailwind.css so a drift in either file fails the build.
#
# 2. Custom properties are gone. No mail client resolves var(), so the layout
#    and the partials read these constants and MJML inlines the literal.
module MailerTheme
  # Drawn on the page.
  BACKGROUND = "#000000"      # --color-background
  SURFACE = "#23272b"         # --color-surface, over BACKGROUND
  # --color-control is byte-identical to --color-surface; see the panel-redesign
  # plan's F10 for why that is worth knowing rather than deduplicating.
  CONTROL = "#23272b"         # --color-control, over BACKGROUND
  CONTROL_HOVER = "#31373d"   # --color-control-hover, over BACKGROUND

  # Drawn on the surface.
  EDGE = "#4f555a"            # --color-edge, over SURFACE
  EDGE_SOFT = "#3b4045"       # --color-edge-soft, over SURFACE
  # The hairline between report rows. email.scss drew it as
  # rgba(#c8c8c8, .12), which is not a token the app has; --color-edge-faint is.
  EDGE_FAINT = "#31363a"      # --color-edge-faint, over SURFACE

  # Opaque already.
  TEXT = "#c8c8c8"            # --color-text
  LIFTED = "#eeeeee"          # --color-lifted
  MUTED = "#7a8288"           # --color-muted
  ENDCAP = "#7a8288"          # --color-endcap
  PRIMARY = "#428bca"         # --color-primary
  DANGER = "#dc3545"          # --color-danger
  WARNING = "#fa6800"         # --color-warning
  SUCCESS = "#5cb85c"         # --color-success
  GOLD = "#d4af37"            # --color-gold

  # The cap a flooded tone wears while hovered. Btn writes it as
  # rgb(255 255 255 / .65) rather than as a token, because on a red or orange
  # surface the primary cap the neutral states borrow is unreadable and the cap
  # has to follow the label to white instead. Resolved here against the flood it
  # is drawn on, which is the tone's own colour - so these two are the only
  # values in this file with no --color-* to mirror, and MailerThemeTest checks
  # them by recomputing the composite instead.
  DANGER_CAP_HOVER = "#f3b8be"
  WARNING_CAP_HOVER = "#fdcaa6"
  FLOOD_TEXT = "#ffffff"

  # The accent, per theme.
  #
  # stylesheets/shared/themes.scss gives the app a theme layer: a theme is a set
  # of tokens components read through var(), selected by data-theme on <html>,
  # and the admin layout sets data-theme="admin". A mail has no <html> we
  # control per recipient and no var() any client would resolve, so the
  # selection happens in Ruby instead - ApplicationMailer.mail_theme is the
  # attribute, and the layout interpolates the literal.
  #
  # The default theme is absent here for the same reason it is absent from
  # themes.scss: PRIMARY above is what a mail that names no theme gets, so it
  # cannot drift out from under one.
  #
  # Only the accent is themed. themes.scss also derives three tones from it -
  # shade, shade-soft, tint - for a rail glow, a hovered toggle border and pill
  # label text, none of which a mail has. Add one here when a mail grows the
  # element that needs it, not before.
  ACCENTS = {
    admin: "#a855f7" # --color-primary under [data-theme="admin"]
  }.freeze

  # Raises rather than falling back, because a mistyped theme that quietly
  # renders the frontend blue is exactly the bug this indirection exists to
  # make impossible.
  def self.accent(theme)
    return PRIMARY if theme.nil?

    ACCENTS.fetch(theme.to_sym) do
      raise ArgumentError,
        "unknown mail theme #{theme.inspect}; MailerTheme::ACCENTS has #{ACCENTS.keys.join(", ")}"
    end
  end

  # Which surface each translucent token composites against. Read by the test.
  BASES = {
    "surface" => :background,
    "control" => :background,
    "control-hover" => :background,
    "edge" => :surface,
    "edge-soft" => :surface,
    "edge-faint" => :surface
  }.freeze

  # Radii, straight from the theme. Outlook Windows ignores border-radius and
  # renders square corners; every other client honours it.
  RADIUS_SURFACE = "16px"     # --radius-surface
  RADIUS_CONTROL = "8px"      # --radius-control

  # End-cap geometry, shared by the panel and the button exactly as the app
  # shares --cap-* between Panel and Btn.
  #
  # The app insets each cap by max(10px, 12%) and straddles the border with it
  # (top: -2px). Email can do neither: max() is unsupported, and nothing can
  # overlap a table border. The inset becomes a plain 12% - the 10px floor only
  # mattered below ~83px wide, and nothing in a 640px mail is - and the cap sits
  # flush against the inside of the frame instead of across it.
  CAP_INSET = "12%"           # --cap-inset
  CAP_WIDTH = "76%"           # what is left between the two insets
  CAP_HEIGHT = "4px"          # --cap-h
  CAP_HEIGHT_BTN = "2px"      # --cap-h-btn, i.e. --cap-h minus 2
  CAP_RADIUS = "3px"          # --cap-r
  CAP_RADIUS_BTN = "1px"      # --cap-r-btn, held to half the cap's own height

  # typography.scss: headings are Open Sans 500 at 1.2, not Orbitron. Orbitron
  # is the tracked-uppercase label face (MetricsCard, CalendarGrid, Hardpoints),
  # so it is used here only where the app uses it. Gmail, Outlook and Yahoo all
  # strip @font-face, and there the tracking and the uppercase carry the label on
  # their own.
  BODY_FONT = "'Open Sans', Helvetica, Arial, sans-serif"
  LABEL_FONT = "Orbitron, 'Open Sans', Helvetica, Arial, sans-serif"

  WIDTH = "640px"             # $global-width, unchanged from the Inky layout
end

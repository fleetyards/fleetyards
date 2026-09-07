# frozen_string_literal: true

# premailer runs on every outgoing mail. Since the move to MJML it is no longer
# there to inline a stylesheet - MJML emits every style inline already - but it
# still generates the text/plain alternative each mail is delivered with, which
# nothing else does.
#
# css_to_attributes is off because of what it does to the layout's backdrop. It
# rewrites a handful of CSS properties into their legacy HTML attribute
# equivalents, and for background-image that means moving the url into a
# `background="..."` attribute and *deleting the declaration*. The rest of the
# group survived - background-position, background-repeat and background-size
# were all still there - so the mail arrived with instructions for how to draw a
# picture it no longer had.
#
# The legacy attribute it produces is not a fair trade: it is the older, less
# widely honoured of the two, and MJML emits the attributes it wants by itself
# (bgcolor, align, width are all in the compiled output already).
Premailer::Rails.config[:css_to_attributes] = false

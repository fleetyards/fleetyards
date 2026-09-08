# frozen_string_literal: true

# Inserted above Rack::Cors (which 02_cors.rb puts at the top of the stack) so
# a header carrying invalid UTF-8 is repaired before rack-cors matches Origin
# against a regexp, and before host authorization splits the Host header.
Rails.application.config.middleware.insert_before 0, Middleware::ScrubHeaderEncoding

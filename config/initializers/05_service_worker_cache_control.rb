# frozen_string_literal: true

# At the top of the stack so it wraps ActionDispatch::Static, which answers
# /sw.js before anything below it runs -- and which is only in the stack when
# static files are served at all, so it cannot be anchored to directly.
Rails.application.config.middleware.insert_before 0, Middleware::ServiceWorkerCacheControl

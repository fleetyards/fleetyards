# frozen_string_literal: true

Spring.watch(
  ".tool-versions",
  ".rbenv-vars",
  "tmp/restart.txt",
  "tmp/caching-dev.txt"
)

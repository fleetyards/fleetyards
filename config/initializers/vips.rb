# frozen_string_literal: true

# libvips gives every operation a thread pool as wide as the machine and keeps
# recent operations cached. Measured on a 7694px render, one thread and no
# cache cut a crop's peak by about a fifth and what stays resident afterwards
# by about two fifths, at no measurable cost in time. Memory, not CPU, is what
# the workers run out of.
require "vips"

Vips.concurrency_set(1)
Vips.cache_set_max(0)

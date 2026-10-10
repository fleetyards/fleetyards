# frozen_string_literal: true

require "lexorank"
require "lexorank/ranking"

# Lexorank 0.4.0 keeps comparing against the upper rank's characters after the
# two ranks have already diverged, so between "3tgd" and "4<" it answers "3X",
# which sorts before both. The record lands in the wrong place, and when the
# answer is a rank a sibling already holds the save hits the unique index.
#
# Once a character has been taken from the lower rank while the upper one is
# larger there, the result already sorts below the upper rank, so every later
# position is bounded by MAX_CHAR alone.
#
# The whole method is replaced, so a newer release has to be checked against it
# before this is kept or dropped.
unless Lexorank::VERSION == "0.4.0"
  raise "lexorank #{Lexorank::VERSION} is not the version #{__FILE__} replaces value_between for"
end

module CoreExtensions
  module Lexorank
    module ValueBetween
      def value_between(before_, after_)
        before = before_ || ::Lexorank::MIN_CHAR
        after = after_ || ::Lexorank::MAX_CHAR

        rank = +""
        below_after = false

        (0..).each do |i|
          prev_char = get_char(before, i, ::Lexorank::MIN_CHAR)
          after_char = below_after ? ::Lexorank::MAX_CHAR : get_char(after, i, ::Lexorank::MAX_CHAR)

          if prev_char == after_char
            rank << prev_char
            next
          end

          mid_char = mid(prev_char, after_char)
          if mid_char == prev_char
            rank << prev_char
            below_after = true
            next
          end

          rank << mid_char
          break
        end

        if rank >= after || (before_ && rank <= before_)
          raise ::Lexorank::InvalidRankError, "Cannot rank between #{before_.inspect} and #{after_.inspect}."
        end

        rank
      end
    end
  end
end

Lexorank::Ranking.prepend(CoreExtensions::Lexorank::ValueBetween)

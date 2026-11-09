# frozen_string_literal: true

require "test_helper"

module Chf
  class ContextTest < ActiveSupport::TestCase
    setup { Context.reset! }

    test "keeps only the newest version of each file parsed" do
      parses = 0
      parse = -> { parses += 1 }

      Context.parsed(:catalog, "a", &parse)
      Context.parsed(:catalog, "a", &parse)
      Context.parsed(:catalog, "b", &parse)
      Context.parsed(:catalog, "a", &parse)

      assert_equal 3, parses
      assert_equal 1, Context.instance_variable_get(:@cache).size
    end
  end
end

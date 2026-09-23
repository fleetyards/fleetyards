# frozen_string_literal: true

require "test_helper"
require "bsky/facets"

module Bsky
  class FacetsTest < ActiveSupport::TestCase
    def ranges(text, facets)
      facets.map { |facet| text.byteslice(facet.dig("index", "byteStart")...facet.dig("index", "byteEnd")) }
    end

    test ".extract links a URL" do
      text = "New ship\nhttps://fleetyards.net/ships/idris-p/"
      facets = Bsky::Facets.extract(text)

      assert_equal ["https://fleetyards.net/ships/idris-p/"], ranges(text, facets)
      assert_equal "app.bsky.richtext.facet#link", facets.first["features"].first["$type"]
      assert_equal "https://fleetyards.net/ships/idris-p/", facets.first["features"].first["uri"]
    end

    test ".extract leaves a sentence-final full stop out of the link" do
      text = "See https://fleetyards.net."

      assert_equal ["https://fleetyards.net"], ranges(text, Bsky::Facets.extract(text))
    end

    test ".extract tags a hashtag without its leading #" do
      text = "Idris-P #starcitizen"
      facets = Bsky::Facets.extract(text)

      assert_equal ["#starcitizen"], ranges(text, facets)
      assert_equal({"$type" => "app.bsky.richtext.facet#tag", "tag" => "starcitizen"}, facets.first["features"].first)
    end

    test ".extract counts byte offsets past multibyte characters" do
      text = "Añvil 🚀 Carrack #starcitizen"

      assert_equal ["#starcitizen"], ranges(text, Bsky::Facets.extract(text))
    end

    test ".extract ignores numbers, mid-word hashes and URL fragments" do
      text = "Ship #1 and C#sharp https://fleetyards.net/#top"
      facets = Bsky::Facets.extract(text)

      assert_equal ["https://fleetyards.net/#top"], ranges(text, facets)
    end

    test ".extract orders facets by position" do
      text = "Carrack\nhttps://fleetyards.net\n#starcitizen"

      assert_equal ["https://fleetyards.net", "#starcitizen"], ranges(text, Bsky::Facets.extract(text))
    end

    test ".extract returns nothing for plain text" do
      assert_empty Bsky::Facets.extract("Hello")
    end
  end
end

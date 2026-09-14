# frozen_string_literal: true

require "test_helper"

class SupporterClaimKeyTest < ActiveSupport::TestCase
  test ".generate produces a prefixed, grouped key from the Crockford alphabet" do
    key = SupporterClaimKey.generate

    assert_match(/\AFY-[0-9A-Z]{4}-[0-9A-Z]{4}\z/, key)
    refute_match(/[ILOU]/, key.delete("-"), "the alphabet must exclude the ambiguous characters")
  end

  test ".generate does not repeat itself" do
    keys = Array.new(50) { SupporterClaimKey.generate }

    assert_equal 50, keys.uniq.size
  end

  test ".normalize accepts the canonical form unchanged" do
    assert_equal "FY-7K2M-9QXD", SupporterClaimKey.normalize("FY-7K2M-9QXD")
  end

  test ".normalize repairs case, separators and a missing prefix" do
    ["fy-7k2m-9qxd", "FY7K2M9QXD", "fy 7k2m 9qxd", "7K2M-9QXD", "  FY-7K2M-9QXD  "].each do |variant|
      assert_equal "FY-7K2M-9QXD", SupporterClaimKey.normalize(variant), variant.inspect
    end
  end

  test ".normalize folds the characters people substitute" do
    assert_equal "FY-1101-1010", SupporterClaimKey.normalize("FY-ILOI-LO10")
  end

  test ".normalize keeps a body that begins with the prefix" do
    assert_equal "FY-FYAB-CDEF", SupporterClaimKey.normalize("FY-FYAB-CDEF")
    assert_equal "FY-FYAB-CDEF", SupporterClaimKey.normalize("FYFYABCDEF")
    assert_equal "FY-FYAB-CDEF", SupporterClaimKey.normalize("FYABCDEF")
  end

  test ".normalize returns nil for anything not key-shaped" do
    [nil, "", "   ", "hello", "FY-123-45", "FY-7K2M-9QXD-EXTRA", "FY-7K2M-9QXU"].each do |value|
      assert_nil SupporterClaimKey.normalize(value), value.inspect
    end
  end

  # Accepting a bare body makes this ambiguous and there is no way around it:
  # eight valid characters are eight valid characters, whether or not the first
  # two happen to spell the prefix. Documented rather than hidden, because the
  # alternative is rejecting the bare form people will paste.
  test ".normalize reads a prefix-shaped eight-character input as a body" do
    assert_equal "FY-FY12-3456", SupporterClaimKey.normalize("FY-123-456")
  end

  test ".extract finds a key inside a donation message" do
    assert_equal "FY-7K2M-9QXD", SupporterClaimKey.extract("thanks for the tool! FY-7K2M-9QXD -- keep going")
  end

  test ".extract finds a key typed without separators" do
    assert_equal "FY-7K2M-9QXD", SupporterClaimKey.extract("my key is fy7k2m9qxd")
  end

  test ".extract returns nil when a message carries no key" do
    [nil, "", "great work, no key here"].each do |message|
      assert_nil SupporterClaimKey.extract(message), message.inspect
    end
  end
end

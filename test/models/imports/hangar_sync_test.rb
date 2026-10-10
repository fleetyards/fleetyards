# frozen_string_literal: true

require "test_helper"

module Imports
  class HangarSyncTest < ActiveSupport::TestCase
    def import_with(import_data)
      ::Imports::HangarSync.new(user: build(:user), import_data:)
    end

    test "#unread_pages reads the pages kept in import_data" do
      pages = [{"check" => "missing_kinds", "page_number" => 2}]

      assert_equal pages, import_with({unread_pages: pages}.to_json).unread_pages
    end

    test "#unread_pages is empty without any, and for data in another shape" do
      assert_equal [], import_with(nil).unread_pages
      assert_equal [], import_with("<li>raw markup</li>").unread_pages
      assert_equal [], import_with("[1, 2]").unread_pages
      assert_equal [], import_with('"null"').unread_pages
    end
  end
end

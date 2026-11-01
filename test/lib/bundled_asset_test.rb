# frozen_string_literal: true

require "test_helper"

class BundledAssetTest < ActiveSupport::TestCase
  test "finds an image in the frontend source" do
    assert_equal Rails.root.join("app/frontend/images/missions/mining.jpg"), BundledAsset.file("images/missions/mining.jpg")
  end

  test "leaves the manifest alone where the source tree exists" do
    ViteRuby.instance.manifest.expects(:path_for).never

    assert_nil BundledAsset.file("images/missions/nope.jpg")
  end

  test "finds the built copy where the source tree is not shipped" do
    Dir.mktmpdir do |dir|
      built = Pathname(dir).join("vite/assets/mining-abc123.jpg")
      FileUtils.mkdir_p(built.dirname)
      FileUtils.touch(built)
      BundledAsset.stubs(:source_root).returns(Pathname(dir).join("missing"))
      Rails.stubs(:public_path).returns(Pathname(dir))
      ViteRuby.instance.manifest.stubs(:path_for).with("images/missions/mining.jpg").returns("/vite/assets/mining-abc123.jpg")

      assert_equal built, BundledAsset.file("images/missions/mining.jpg")
    end
  end

  test "answers nil for an image Vite never bundled" do
    BundledAsset.stubs(:source_root).returns(Rails.root.join("tmp/missing"))

    assert_nil BundledAsset.file("images/missions/nope.jpg")
  end
end

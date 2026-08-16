# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class BaseParserTest < ActiveSupport::TestCase
      setup do
        @base_folder = Dir.mktmpdir
        @export_path = "#{@base_folder}/parsed/test"

        # The only file the constructor insists on.
        FileUtils.mkdir_p("#{@base_folder}/raw/1.0.0/Data/Localization/english")
        File.write("#{@base_folder}/raw/1.0.0/Data/Localization/english/global.ini", "")

        @parser = ::ScData::Parser::BaseParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      # Without this the file survives every later parse, the loader keeps
      # reading it as part of the build, and nothing downstream can tell it
      # apart from a record the game files still carry.
      test "#save_items drops the file of a record the run no longer parses" do
        write_parsed("items", "gone")

        @parser.send(:save_items, [{key: "kept"}], folder: "items")

        assert_equal ["kept.json"], parsed_files("items")
      end

      # `items` and `models` are filled by several passes, so clearing per call
      # would leave only whatever the last pass wrote.
      test "#save_items keeps what an earlier pass of the same run wrote" do
        @parser.send(:save_items, [{key: "first"}], folder: "items")
        @parser.send(:save_items, [{key: "second"}], folder: "items")

        assert_equal ["first.json", "second.json"], parsed_files("items")
      end

      test "#save_items leaves the folder alone when a pass parsed nothing" do
        write_parsed("items", "kept")

        @parser.send(:save_items, [], folder: "items")

        assert_equal ["kept.json"], parsed_files("items")
      end

      test "#save_items clears each folder on its own first write" do
        write_parsed("items", "gone")
        write_parsed("models", "also_gone")

        @parser.send(:save_items, [{key: "kept"}], folder: "items")
        @parser.send(:save_items, [{key: "kept_model"}], folder: "models")

        assert_equal ["kept.json"], parsed_files("items")
        assert_equal ["kept_model.json"], parsed_files("models")
      end

      # Records name the source art -- a .tif that the export ships as a
      # CryEngine texture -- so a parse has to find it under another extension
      # and leave a browser something it can draw.
      test "#save_icon converts a texture the record names as a tif" do
        requires_imagemagick

        write_texture("ui/logos/acme_256.dds")

        target = @parser.send(:save_icon, "ui/logos/acme_256.tif")

        assert_equal "#{@export_path}/icons/ui/logos/acme_256.png", target
        assert_equal "PNG", MiniMagick::Image.open(target).type
      end

      # ImageMagick stamps the moment of conversion into what it writes, so
      # without the chunks excluded a parse that changed nothing still rewrites
      # every icon it touched and the diff claims they all changed.
      test "#save_icon writes the same bytes for a source that has not changed" do
        requires_imagemagick

        write_texture("ui/logos/acme_256.dds")

        target = @parser.send(:save_icon, "ui/logos/acme_256.tif")
        first = File.binread(target)

        @parser.send(:save_icon, "ui/logos/acme_256.tif")

        assert_equal first, File.binread(target)
      end

      # The export is moving to PNG, and re-encoding one would cost quality for
      # nothing. No ImageMagick either, which is the point.
      test "#save_icon copies a texture the export already ships as a png" do
        FileUtils.mkdir_p("#{@base_folder}/raw/1.0.0/Data/ui/logos")
        source = "#{@base_folder}/raw/1.0.0/Data/ui/logos/acme_256.png"
        FileUtils.cp(Rails.root.join("test/fixtures/files/test.png"), source)

        target = @parser.send(:save_icon, "ui/logos/acme_256.tif")

        assert_equal "#{@export_path}/icons/ui/logos/acme_256.png", target
        assert_equal File.binread(source), File.binread(target)
      end

      # The export is moving to PNG and may ship both for a while. Converting
      # the texture when a ready-to-serve copy sits beside it would be work for
      # a worse result.
      test "#save_icon prefers the drawable copy over the texture beside it" do
        FileUtils.mkdir_p("#{@base_folder}/raw/1.0.0/Data/ui/logos")
        FileUtils.cp(Rails.root.join("test/fixtures/files/test.png"),
          "#{@base_folder}/raw/1.0.0/Data/ui/logos/acme_256.png")
        File.write("#{@base_folder}/raw/1.0.0/Data/ui/logos/acme_256.dds", "not a texture at all")

        target = @parser.send(:save_icon, "ui/logos/acme_256.tif")

        assert_equal File.binread(Rails.root.join("test/fixtures/files/test.png")), File.binread(target)
      end

      # Vectors are already drawable, and rasterising one would only lose it
      # its resolution.
      test "#save_icon copies a vector icon as it is" do
        source = write_asset("ui/logos/acme.svg", "<svg xmlns='http://www.w3.org/2000/svg'/>")

        target = @parser.send(:save_icon, "ui/logos/acme.svg")

        assert_equal "#{@export_path}/icons/ui/logos/acme.svg", target
        assert_equal File.read(source), File.read(target)
      end

      # The split form: a header with no surface, and the picture itself in a
      # numbered companion beside it.
      test "#save_icon reassembles a texture whose surface sits beside it" do
        requires_imagemagick

        texture = write_texture("ui/logos/split_256.dds")
        bytes = File.binread(texture)
        File.binwrite(texture, bytes[0, 128])
        File.binwrite("#{texture}.1", bytes[128..])

        target = @parser.send(:save_icon, "ui/logos/split_256.tif")

        assert_equal "#{@export_path}/icons/ui/logos/split_256.png", target
        assert_equal 16, MiniMagick::Image.open(target).width
      end

      # Every catalogue writes into the same icons root, so sweeping that root
      # would leave whichever parser ran last as the only one with artwork.
      test "#save_icon leaves the icons another catalogue wrote alone" do
        write_asset("ui/logos/acme.svg", "<svg xmlns='http://www.w3.org/2000/svg'/>")
        write_asset("ui/items/widget.svg", "<svg xmlns='http://www.w3.org/2000/svg'/>")

        @parser.send(:save_icon, "ui/logos/acme.svg")

        # A second catalogue is a second parser, with its own idea of what it
        # has already cleared.
        ::ScData::Parser::BaseParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        ).send(:save_icon, "ui/items/widget.svg")

        assert_path_exists "#{@export_path}/icons/ui/logos/acme.svg"
        assert_path_exists "#{@export_path}/icons/ui/items/widget.svg"
      end

      test "#save_icon drops an icon its own folder no longer names" do
        FileUtils.mkdir_p("#{@export_path}/icons/ui/logos")
        File.write("#{@export_path}/icons/ui/logos/gone.svg", "")
        write_asset("ui/logos/acme.svg", "<svg xmlns='http://www.w3.org/2000/svg'/>")

        @parser.send(:save_icon, "ui/logos/acme.svg")

        assert_equal ["acme.svg"], Dir.children("#{@export_path}/icons/ui/logos")
      end

      test "#save_icon writes nothing when the export carries no such asset" do
        assert_nil @parser.send(:save_icon, "ui/logos/missing_256.tif")
        assert_not File.directory?("#{@export_path}/icons")
      end

      # Textures are converted where the export is parsed: a machine with the
      # raw dump and ImageMagick on it. Neither CI nor production has either --
      # the loader only reads what the parse already wrote -- so the two cases
      # that shell out say so rather than failing there.
      private def requires_imagemagick
        skip("ImageMagick is not installed") unless imagemagick?
      end

      private def imagemagick?
        return @imagemagick if defined?(@imagemagick)

        @imagemagick = %w[magick convert].any? do |binary|
          system(binary, "-version", out: File::NULL, err: File::NULL)
        end
      end

      private def write_texture(path)
        target = "#{@base_folder}/raw/1.0.0/Data/#{path}"

        FileUtils.mkdir_p(File.dirname(target))
        MiniMagick.convert.size("16x16").tap { |c| c << "xc:red" }.tap { |c| c << target }.call

        target
      end

      private def write_asset(path, contents)
        target = "#{@base_folder}/raw/1.0.0/Data/#{path}"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, contents)

        target
      end

      private def write_parsed(folder, name)
        FileUtils.mkdir_p("#{@export_path}/#{folder}")
        File.write("#{@export_path}/#{folder}/#{name}.json", "{}")
      end

      private def parsed_files(folder)
        Dir.children("#{@export_path}/#{folder}").sort
      end
    end
  end
end

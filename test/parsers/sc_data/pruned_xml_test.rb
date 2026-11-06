# frozen_string_literal: true

require "test_helper"
require "tempfile"

module ScData
  module Parser
    class PrunedXmlTest < ActiveSupport::TestCase
      test ".read drops the named elements with everything nested in them" do
        xml = read(<<~XML)
          <root>
            <kept a="1"><drop><drop><lost /></drop><lost /></drop><inner>text</inner></kept>
            <drop b="2" />
          </root>
        XML

        assert_equal({"root" => {"kept" => {"a" => "1", "inner" => "text"}}}, Hash.from_xml(xml))
      end

      test ".read keeps what the XML had to escape" do
        xml = read(%(<root title="&quot;a&quot; &amp; &lt;b&gt;"><child>x &amp; &lt;y&gt;</child></root>))

        assert_equal({"root" => {"title" => %("a" & <b>), "child" => "x & <y>"}}, Hash.from_xml(xml))
      end

      test ".read keeps a parent as a hash when its only child is dropped" do
        xml = read(<<~XML)
          <root>
            <parent>
              <drop />
            </parent>
            <kept>1</kept>
          </root>
        XML

        assert_equal({"root" => {"parent" => nil, "kept" => "1"}}, Hash.from_xml(xml))
      end

      test ".read raises rather than returning a truncated file" do
        error = assert_raises(ArgumentError) { read("<root><unclosed></root>") }

        assert_match(/pruned.*\.xml/, error.message)
      end

      private def read(content)
        Tempfile.create(["pruned", ".xml"]) do |file|
          file.write(content)
          file.flush

          ScData::Parser::PrunedXml.read(file.path, without: %w[drop])
        end
      end
    end
  end
end

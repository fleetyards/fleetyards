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

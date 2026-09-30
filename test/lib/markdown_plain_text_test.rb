# frozen_string_literal: true

require "test_helper"

class MarkdownPlainTextTest < ActiveSupport::TestCase
  test "drops the markup and keeps the words and link targets" do
    text = MarkdownPlainText.render("## Brief\n\n**Meet** at *Olisar*\n\n- one\n- two\n\n[Map](https://x.test)")

    assert_equal "Brief\nMeet at Olisar\none\ntwo\nMap (https://x.test)", text
  end

  test "reads the editor's escapes and entities as characters" do
    assert_equal "Some [TM] & <more>", MarkdownPlainText.render("Some \\[TM\\] &amp; &lt;more&gt;")
  end

  test "drops the centre fences but keeps what they hold" do
    assert_equal "Welcome\nMore", MarkdownPlainText.render(":::center\n\nWelcome\n\n:::\n\nMore")
  end

  test "is empty for no text" do
    assert_equal "", MarkdownPlainText.render(nil)
  end
end

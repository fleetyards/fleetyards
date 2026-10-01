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

  test "leaves an image's size out" do
    assert_equal "Before\ncover https://x.test/a.jpg\nAfter",
      MarkdownPlainText.render("Before\n\n![cover](https://x.test/a.jpg){width=50%}\n\nAfter")
  end

  test "leaves the size out of an image whose description has brackets" do
    text = MarkdownPlainText.render("![Fleet [Alpha]](https://x.test/a.jpg){width=50%}")

    assert_not_includes text, "{width"
  end

  test "keeps a width the page does not read as a size" do
    assert_includes MarkdownPlainText.render("![a](https://x.test/a.jpg){width=33%}"), "{width=33%}"
  end

  test "reads a catalogue token as the item's name" do
    assert_equal "Fit Attrition-3 Repeater or Mercury", MarkdownPlainText.render("Fit [*Attrition-3 Repeater*] or [*commodity:Mercury*]")
  end

  test "keeps a token written as code" do
    text = MarkdownPlainText.render("Type `[*Name*]` to name one\n\n```\n[*ship:Carrack*]\n```\n\nor [*ship:Carrack*]")

    assert_includes text, "[*Name*]"
    assert_includes text, "[*ship:Carrack*]"
    assert text.end_with?("or Carrack"), text
  end

  test "reads a token between escaped backticks as prose" do
    assert_equal "See `Carrack` here", MarkdownPlainText.render("See \\`[*ship:Carrack*]\\` here")
  end

  test "is empty for no text" do
    assert_equal "", MarkdownPlainText.render(nil)
  end
end

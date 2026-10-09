# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260930100000_convert_fleet_descriptions_to_markdown.rb")

class ConvertFleetDescriptionsToMarkdownTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet, created_by: create(:user).id)
  end

  test "tags become the markdown that means the same" do
    write_description(<<~HTML)
      <b>Welcome</b> to <i>the <u>crew</u></i>
      <ul>
      <li><a href="https://fleetyards.net/fleets/crew/ships/">The Fleet</a></li>
      <li><a href='https://fleetyards.net/fleets/crew/stats/'>Stats</a></li>
      </ul>
      <img src="https://robertsspaceindustries.com/media/cover.jpg" />
    HTML

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal <<~MARKDOWN.strip, @fleet.reload.description
      **Welcome** to *the crew*

      - [The Fleet](https://fleetyards.net/fleets/crew/ships/)
      - [Stats](https://fleetyards.net/fleets/crew/stats/)

      ![](https://robertsspaceindustries.com/media/cover.jpg)
    MARKDOWN
  end

  test "a centred passage becomes a center block" do
    write_description("<center>Welcome to the\n<b>Crew</b></center>\nMore")

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal ":::center\nWelcome to the\n**Crew**\n:::\n\nMore", @fleet.reload.description
  end

  test "emphasis keeps its spaces outside the markers" do
    write_description("the <b>banner. </b>Our goal")

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal "the **banner.** Our goal", @fleet.reload.description
  end

  test "emphasis over several lines is balanced on each" do
    write_description("<b>First\nSecond</b>")

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal "**First**\n**Second**", @fleet.reload.description
  end

  test "same-origin paths are kept and other origins dropped" do
    write_description(%(<a href="/fleets/maru">Maru</a> <a href="//evil.test">x</a><img src="/cover.jpg">))

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal "[Maru](/fleets/maru) x![](/cover.jpg)", @fleet.reload.description
  end

  test "parentheses in a url are encoded so the link does not end early" do
    write_description(%(<a href="https://example.org/wiki/Ship_(game)">Ship</a>))

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal "[Ship](https://example.org/wiki/Ship_%28game%29)", @fleet.reload.description
  end

  test "a script or a javascript link does not survive as markup" do
    write_description(%(Hi\n<script>alert(1)</script><a href="javascript:alert(1)">click</a><img src=x onerror=alert(1)>))

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal "Hi\nclick", @fleet.reload.description
  end

  test "angle brackets that are not a tag are left alone" do
    description = "<< DAKKAR Corporation >>\n<----- over there"
    write_description(description)

    ConvertFleetDescriptionsToMarkdown.new.up

    assert_equal description, @fleet.reload.description
  end

  private

  def write_description(description)
    @fleet.update_columns(description:)
  end
end

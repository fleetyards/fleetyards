# frozen_string_literal: true

require "openapi_helper"

class Api::V1::SupportersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/supporters" do
    get("Public list of everyone who has supported the project") do
      operationId "supporters"
      tags "Supporters"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::SupportersOverview
      end
    end
  end

  test "GET /supporters includes supporters from past months, sorted by name" do
    create(:supporter_contribution, name: "Zoe", started_at: 3.years.ago.to_date)
    create(:supporter_contribution, name: "alice", started_at: 2.months.ago.to_date)
    create(:supporter_contribution, name: "Bob", started_at: Date.current)

    assert_api_response :get, 200 do
      assert_equal %w[alice Bob Zoe], names
    end
  end

  test "GET /supporters includes a recurring pledge that has ended" do
    create(:supporter_contribution, :recurring, name: "Carla", started_at: 2.years.ago.to_date, ended_at: 1.year.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal %w[Carla], names
    end
  end

  # Every Ko-fi payment is a row of its own, so a monthly supporter would
  # otherwise fill the list on their own.
  test "GET /supporters lists an account once however many times it paid" do
    user = create(:user, :public_hangar, username: "monthly")
    create(:supporter_contribution, user:, started_at: 3.months.ago.to_date)
    create(:supporter_contribution, user:, started_at: 2.months.ago.to_date)
    create(:supporter_contribution, user:, started_at: 1.month.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal %w[monthly], names
    end
  end

  test "GET /supporters merges a name reported with different casing and spacing" do
    create(:supporter_contribution, name: "Elfwyn ", started_at: 3.months.ago.to_date)
    create(:supporter_contribution, name: "elfwyn", started_at: 2.months.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal 1, entries.count
    end
  end

  test "GET /supporters keeps the profile link when an unlinked payment has the same name" do
    user = create(:user, :public_hangar, username: "sameperson")
    create(:supporter_contribution, name: "SamePerson", started_at: 3.months.ago.to_date)
    create(:supporter_contribution, user:, started_at: 2.months.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal 1, entries.count
      assert_equal "sameperson", entries.first["username"]
    end
  end

  test "GET /supporters links a public hangar but not a private one" do
    public_user = create(:user, :public_hangar, username: "open")
    private_user = create(:user, :private_hangar, username: "closed")
    create(:supporter_contribution, user: public_user, started_at: 1.year.ago.to_date)
    create(:supporter_contribution, user: private_user, started_at: 1.year.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal "open", entries.find { |entry| entry["displayName"] == "open" }["username"]
      refute entries.find { |entry| entry["displayName"] == "closed" }.key?("username")
    end
  end

  test "GET /supporters names a linked account by its username, not the payer's name" do
    user = create(:user, username: "dorasupports")
    create(:supporter_contribution, name: "Dora Realname", user:, started_at: 1.year.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal %w[dorasupports], names
    end
  end

  test "GET /supporters omits anonymous contributions" do
    create(:supporter_contribution, :anonymous, name: "Erin", started_at: 1.year.ago.to_date)
    create(:supporter_contribution, name: nil, started_at: 1.year.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal [], entries
    end
  end

  test "GET /supporters respects the account's answer over the platform's" do
    hidden = create(:user, username: "hidden", supporter_listed: false)
    shown = create(:user, username: "shown", supporter_listed: true)
    create(:supporter_contribution, user: hidden, started_at: 1.year.ago.to_date)
    create(:supporter_contribution, :anonymous, user: shown, started_at: 1.year.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal %w[shown], names
    end
  end

  # Deleting an account unlinks its payments and keeps the money on the books.
  # What is left carries the name the payer typed at the platform, often their
  # real one, which must not resurface once the account is gone.
  test "GET /supporters drops a supporter whose account was deleted" do
    user = create(:user, username: "leaving", supporter_listed: true)
    create(:supporter_contribution, name: "Real Name", anonymous: false, user:, started_at: 1.year.ago.to_date)

    user.destroy!

    assert_api_response :get, 200 do
      assert_equal [], entries
    end
  end

  test "GET /supporters does not state how much anybody gave" do
    create(:supporter_contribution, name: "Alice", amount_cents: 1_000, started_at: 1.year.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal %w[displayName], entries.first.keys
    end
  end

  test "GET /supporters leaves out a contribution dated in the future" do
    create(:supporter_contribution, name: "Soon", started_at: 1.month.from_now.to_date)

    assert_api_response :get, 200 do
      assert_equal [], entries
    end
  end

  test "GET /supporters counts hidden supporters without naming them" do
    create(:supporter_contribution, :anonymous, name: "Erin", started_at: 1.year.ago.to_date)
    create(:supporter_contribution, :anonymous, name: "Erin ", started_at: 2.years.ago.to_date)
    create(:supporter_contribution, name: nil, started_at: 1.year.ago.to_date)
    hidden = create(:user, supporter_listed: false)
    create(:supporter_contribution, user: hidden, started_at: 1.year.ago.to_date)
    create(:supporter_contribution, user: hidden, started_at: 1.month.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal [], entries
      assert_equal 3, parsed_body["anonymousCount"]
      refute_includes response.body, "Erin"
    end
  end

  test "GET /supporters does not count a named supporter's anonymous donation" do
    user = create(:user, username: "mixed")
    create(:supporter_contribution, user:, started_at: 2.months.ago.to_date)
    create(:supporter_contribution, :anonymous, user:, started_at: 1.month.ago.to_date)

    assert_api_response :get, 200 do
      assert_equal %w[mixed], names
      assert_equal 0, parsed_body["anonymousCount"]
    end
  end

  private def entries
    parsed_body["supporters"]
  end

  private def names
    entries.map { |entry| entry["displayName"] }
  end
end

# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: the interactions endpoint is
# Discord's RPC surface, not public API, so it must not contribute to the
# generated OpenAPI schema.
class DiscordInteractionsTest < ActionDispatch::IntegrationTest
  PATH = "/discord/interactions"

  setup do
    @key = OpenSSL::PKey.generate_key("ED25519")
    Discord::SignatureVerifier.stubs(:public_key).returns(@key.raw_public_key.unpack1("H*"))
    Discord::CommandJob.jobs.clear
  end

  def post_signed(payload, timestamp: Time.current.to_i.to_s, signature: nil)
    body = payload.to_json
    signature ||= @key.sign(nil, "#{timestamp}#{body}").unpack1("H*")

    post PATH,
      params: body,
      headers: {
        "CONTENT_TYPE" => "application/json",
        "X-Signature-Ed25519" => signature,
        "X-Signature-Timestamp" => timestamp
      }
  end

  def command_payload(name: "ship", options: [{"name" => "name", "value" => "Carrack"}])
    {
      type: 2,
      application_id: "488788875699945472",
      token: "interaction-token",
      guild_id: "123456789",
      locale: "de",
      member: {user: {id: "42"}},
      data: {name: name, options: options}
    }
  end

  # Discord nests a subcommand as an option of type 1 whose own `options` carry
  # the arguments; there is no `value` on the subcommand itself.
  def subcommand_payload(name: "fleet", subcommand: "info", options: [])
    command_payload(
      name: name,
      options: [{"name" => subcommand, "type" => 1, "options" => options}]
    )
  end

  test "answers a ping with a pong" do
    post_signed({type: 1})

    assert_response :success
    assert_equal 1, response.parsed_body["type"]
  end

  # Discord probes a newly saved endpoint URL with a bad signature and will not
  # accept the URL unless the probe is rejected.
  test "rejects a request whose signature does not match the body" do
    post_signed({type: 1}, signature: "00" * 64)

    assert_response :unauthorized
  end

  test "rejects a request without signature headers" do
    post PATH, params: {type: 1}.to_json, headers: {"CONTENT_TYPE" => "application/json"}

    assert_response :unauthorized
  end

  test "rejects a replayed request outside the timestamp window" do
    stale = (Time.current - Discord::SignatureVerifier::MAX_AGE - 1.minute).to_i.to_s

    post_signed({type: 1}, timestamp: stale)

    assert_response :unauthorized
  end

  test "rejects everything while no public key is configured" do
    Discord::SignatureVerifier.stubs(:public_key).returns(nil)

    post_signed({type: 1})

    assert_response :unauthorized
  end

  class WithCommandsEnabled < DiscordInteractionsTest
    setup { Flipper.enable(:discord_commands) }

    test "acknowledges a command with a deferred response" do
      post_signed(command_payload)

      assert_response :success
      assert_equal 5, response.parsed_body["type"]
    end

    # The acknowledgement is the only place Discord reads visibility: it fixes
    # it there and ignores flags on the follow-up. A command that answers in
    # the channel must therefore acknowledge without the ephemeral flag.
    test "a public command is acknowledged without the ephemeral flag" do
      post_signed(command_payload)

      assert_nil response.parsed_body.dig("data", "flags")
    end

    test "an unknown command is acknowledged privately" do
      post_signed(command_payload(name: "definitely-not-a-command"))

      assert_equal 64, response.parsed_body.dig("data", "flags")
    end

    test "every registered command is acknowledged the way the registry declares" do
      Discord::Commands::Registry::DEFINITIONS.each do |definition|
        children = Discord::Commands::Registry.subcommands(definition)

        calls =
          if children.empty?
            [[command_payload(name: definition[:name]), nil]]
          else
            children.map { |child| [subcommand_payload(name: definition[:name], subcommand: child[:name]), child[:name]] }
          end

        calls.each do |payload, subcommand|
          post_signed(payload)

          label = "/#{[definition[:name], subcommand].compact.join(" ")}"
          flags = response.parsed_body.dig("data", "flags")

          if Discord::Commands::Registry.ephemeral?(definition[:name], subcommand)
            assert_equal 64, flags, "#{label} should answer privately"
          else
            assert_nil flags, "#{label} should answer in the channel"
          end
        end
      end
    end

    test "enqueues a subcommand with the arguments nested under it" do
      post_signed(
        subcommand_payload(options: [{"name" => "limit", "value" => 5}])
      )

      context = Discord::CommandJob.jobs.first["args"].first

      assert_equal "fleet", context["command"]
      assert_equal "info", context["subcommand"]
      assert_equal({"limit" => 5}, context["options"])
    end

    # A flat read of the top-level options would find the subcommand itself,
    # which carries no value, and drop every argument the caller typed.
    test "a subcommand does not leak into the options hash" do
      post_signed(subcommand_payload)

      context = Discord::CommandJob.jobs.first["args"].first

      assert_equal({}, context["options"])
    end

    # Discord will not invoke a command that has subcommands, but the endpoint is
    # public: a hand-rolled bare call must not dispatch to the parent.
    test "a bare call to a command with subcommands is acknowledged privately" do
      post_signed(command_payload(name: "fleet", options: []))

      assert_equal 64, response.parsed_body.dig("data", "flags")
      assert_nil Discord::CommandJob.jobs.first["args"].first["subcommand"]
    end

    test "enqueues the command with everything the job needs" do
      post_signed(command_payload)

      assert_equal 1, Discord::CommandJob.jobs.size

      context = Discord::CommandJob.jobs.first["args"].first

      assert_equal "ship", context["command"]
      assert_equal({"name" => "Carrack"}, context["options"])
      assert_equal "interaction-token", context["token"]
      assert_equal "488788875699945472", context["application_id"]
      assert_equal "123456789", context["guild_id"]
      assert_equal "42", context["discord_user_id"]
      assert_equal "de", context["locale"]
      assert context["requested_at"].present?
    end

    test "an unknown command name is still acknowledged rather than dropped" do
      post_signed(command_payload(name: "nope"))

      assert_response :success
      assert_equal 5, response.parsed_body["type"]
    end

    test "an unknown interaction type is answered without content" do
      post_signed({type: 99})

      assert_response :no_content
      assert_equal 0, Discord::CommandJob.jobs.size
    end
  end

  class WithCommandsDisabled < DiscordInteractionsTest
    setup { Flipper.disable(:discord_commands) }

    test "answers a command with a message instead of running it" do
      post_signed(command_payload)

      assert_response :success
      assert_equal 4, response.parsed_body["type"]
      assert_equal 0, Discord::CommandJob.jobs.size
    end

    test "still answers a ping so the endpoint URL can be saved" do
      post_signed({type: 1})

      assert_response :success
      assert_equal 1, response.parsed_body["type"]
    end
  end
end

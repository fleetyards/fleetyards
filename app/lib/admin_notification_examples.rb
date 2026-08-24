# frozen_string_literal: true

# Fixture data for the notification center, shared by the
# `admin_notifications:examples` rake task and the e2e scenario. Covers what the
# list and the reading pane have to survive: every type and severity, read and
# unread, a body that scrolls and no body at all, a repeat report, and an age
# spread so the list is not one timestamp.
module AdminNotificationExamples
  module_function

  def create_for(admin_user)
    examples.each do |example|
      occurred_at = example[:age].ago

      AdminNotification.create!(
        admin_user:,
        notification_type: example[:type],
        title: example[:title],
        body: example[:body],
        severity: example.fetch(:severity, :info),
        link: example[:link],
        icon: AdminNotification.icon_for(example[:type]),
        occurrences: example.fetch(:occurrences, 1),
        read_at: example[:read] ? occurred_at + 1.minute : nil,
        last_occurred_at: occurred_at,
        created_at: occurred_at,
        updated_at: occurred_at
      )
    end.size
  end

  def examples
    [
      {
        type: :rsi_api_blocked,
        severity: :error,
        title: "RSI blocked a request",
        body: "https://robertsspaceindustries.com/ship-matrix/index",
        link: "/maintenance/rsi-api-status",
        occurrences: 12,
        age: 8.minutes
      },
      {
        type: :modules_import,
        severity: :warning,
        title: "Modules Import Results",
        body: <<~BODY,
          ## Missing Models (3)

          - **Retaliator Bomber**
          - **Reclaimer**
          - **Hull C**

          Add a mapping for each in `modules_importer.rb`, then run the import again.
        BODY
        link: "/models",
        occurrences: 3,
        age: 42.minutes
      },
      {
        type: :loaner_sync,
        title: "Loaner Sync finished",
        age: 2.hours
      },
      {
        type: :new_supporter,
        title: "New Patreon Supporter",
        body: "Jane Doe — $10.00",
        link: "/supporter-contributions",
        age: 5.hours
      },
      {
        type: :uex_commodity_prices_import,
        severity: :warning,
        title: "UEX Commodity Sync Results",
        body: <<~BODY,
          ## Unmatched Commodities (2)

          - **Quantanium (Raw)**
          - **Ranta Dung**

          Everything else updated.
        BODY
        link: "/commodities",
        age: 9.hours
      },
      {
        type: :paints_import,
        title: "Paints Import Results",
        body: <<~BODY,
          ## Imported (2 models)

          - **Aurora MR** — 4 paints
          - **Cutlass Black** — 2 paints

          Nothing needed a decision.
        BODY
        link: "/models",
        read: true,
        age: 1.day
      },
      {
        type: :uex_prices_import,
        title: "UEX Price Sync Results",
        body: long_body,
        read: true,
        age: 2.days
      },
      {
        type: :rsi_api_unblocked,
        title: "RSI unblocked a request",
        body: "https://robertsspaceindustries.com/ship-matrix/index",
        link: "/maintenance/rsi-api-status",
        read: true,
        age: 4.days
      },
      {
        type: :weekly_stats,
        title: "Weekly Report",
        body: <<~BODY,
          ## Last Week

          - **Users**: 412 (+18)
          - **Hangars**: 1.204 ships added
          - **Fleets**: 9 created
          - **Supporters**: 3 new

          Full numbers on the [stats page](/stats).
        BODY
        link: "/stats",
        read: true,
        age: 12.days
      }
    ]
  end

  # Long enough that the reading pane has to scroll rather than grow past the
  # viewport.
  def long_body
    models = [
      "Aurora ES", "Aurora LN", "Avenger Titan", "Buccaneer", "Carrack",
      "Constellation Andromeda", "Cutlass Black", "Cutter", "Defender",
      "Dragonfly Black", "Freelancer", "Gladius", "Hammerhead", "Herald",
      "Hornet F7C", "Hull A", "Khartu-al", "Mercury Star Runner", "Mustang Alpha",
      "Nomad", "Prospector", "Reclaimer", "Redeemer", "Sabre", "Scorpius",
      "Spirit C1", "Starfarer", "Terrapin", "Valkyrie", "Vanguard Warden"
    ]

    <<~BODY
      ## Updated Prices (#{models.size})

      #{models.map { |model| "- **#{model}**" }.join("\n")}

      No model was left without a price.
    BODY
  end
end

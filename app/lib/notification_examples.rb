# frozen_string_literal: true

# Fixture data for the user-facing notification center, used by the e2e
# scenario. Covers what the list and the reading pane have to survive: several
# types, read and unread, an archived one, a body with markdown in it and none
# at all, and an age spread so the list is not one timestamp.
module NotificationExamples
  module_function

  def create_for(user)
    examples.each do |example|
      occurred_at = example[:age].ago

      Notification.create!(
        user:,
        notification_type: example[:type],
        title: example[:title],
        body: example[:body],
        link: example[:link],
        icon: example[:icon],
        read_at: example[:read] ? occurred_at + 1.minute : nil,
        archived_at: example[:archived] ? occurred_at + 2.minutes : nil,
        created_at: occurred_at,
        updated_at: occurred_at
      )
    end.size
  end

  def examples
    [
      {
        type: :fleet_invite,
        title: "You were invited to Test Fleet",
        body: "Accept the invite to see the fleet's hangar and events.",
        link: "/fleets",
        icon: "fa-duotone fa-users",
        age: 6.minutes
      },
      {
        type: :hangar_sync_failed,
        title: "Hangar sync failed",
        body: <<~BODY,
          The RSI website did not answer in time.

          - Started: 10 minutes ago
          - Ships imported: **0**

          Try again from the hangar.
        BODY
        link: "/hangar",
        icon: "fa-duotone fa-rotate-exclamation",
        age: 35.minutes
      },
      {
        type: :hangar_create,
        title: "Aurora MR added to your hangar",
        icon: "fa-duotone fa-warehouse",
        age: 3.hours
      },
      {
        type: :model_on_sale,
        title: "Cutlass Black is on sale",
        body: "Available until the end of the week.",
        link: "/ships/cutlass-black",
        icon: "fa-duotone fa-tags",
        age: 8.hours
      },
      {
        type: :fleet_event_starting_soon,
        title: "Mining Run starts in an hour",
        body: "Meet at Port Olisar. Bring a Prospector if you have one.",
        link: "/fleets",
        icon: "fa-duotone fa-calendar-clock",
        read: true,
        age: 1.day
      },
      {
        type: :wishlist_create,
        title: "Carrack added to your wishlist",
        icon: "fa-duotone fa-heart",
        read: true,
        age: 2.days
      },
      {
        type: :hangar_sync_finished,
        title: "Hangar sync finished",
        body: "18 ships imported, 2 updated.",
        link: "/hangar",
        icon: "fa-duotone fa-rotate",
        read: true,
        archived: true,
        age: 5.days
      },
      {
        type: :new_model,
        title: "A new ship was released: Spirit C1",
        body: "The Spirit C1 is now in the ship matrix.",
        link: "/ships/spirit-c1",
        icon: "fa-duotone fa-starship",
        read: true,
        archived: true,
        age: 9.days
      }
    ]
  end
end

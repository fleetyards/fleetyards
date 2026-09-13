module Public
  # What somebody who is not this user may read of their hangar.
  #
  # Each surface asks the same question twice: is it public, and failing that,
  # is it open to friends and is the reader one. A relationship only ever widens
  # an audience from nobody to this user's friends -- it can never reach past a
  # switch that is off, and `public_hangar` being on makes the friend column
  # irrelevant rather than contradictory.
  class UserPolicy < ApplicationPolicy
    def show?
      record.public_hangar? || open_to_friends?(:friends_hangar)
    end

    def show_stats?
      record.public_hangar_stats? || open_to_friends?(:friends_hangar_stats)
    end

    def wishlist?
      record.public_wishlist? || open_to_friends?(:friends_wishlist)
    end

    private def open_to_friends?(setting)
      return false unless record.public_send(:"#{setting}?")

      friend?
    end

    private def friend?
      return false if user.blank?

      user.friend_of?(record)
    end
  end
end

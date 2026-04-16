module Public
  class UserPolicy < ApplicationPolicy
    def show?
      record.public_hangar?
    end

    def show_stats?
      record.public_hangar_stats?
    end

    def wishlist?
      record.public_wishlist?
    end
  end
end

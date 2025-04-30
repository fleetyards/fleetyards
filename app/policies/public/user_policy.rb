module Public
  class UserPolicy < ApplicationPolicy
    def show?
      record.public_hangar?
    end

    def wishlist?
      record.public_wishlist?
    end
  end
end

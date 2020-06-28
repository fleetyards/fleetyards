# frozen_string_literal: true

class AdminUser < ApplicationRecord
  devise :database_authenticatable, :async,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable, authentication_keys: [:username]
end

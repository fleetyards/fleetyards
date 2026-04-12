# frozen_string_literal: true

require "rails_helper"

RSpec.describe OmniauthConnection, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it "enforces one connection per provider per user" do
      connection = create(:omniauth_connection, provider: :discord)
      duplicate = build(:omniauth_connection, user: connection.user, provider: :discord)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:provider]).to be_present
    end

    it "allows same provider for different users" do
      create(:omniauth_connection, provider: :discord)
      other = build(:omniauth_connection, provider: :discord)

      expect(other).to be_valid
    end
  end

  describe "provider enum" do
    it "defines expected providers" do
      expect(described_class.providers).to eq(
        "google" => 0,
        "discord" => 1,
        "github" => 2,
        "bluesky" => 3,
        "twitch" => 4
      )
    end
  end
end

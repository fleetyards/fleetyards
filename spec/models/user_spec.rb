# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "url validation" do
    let(:user) { create(:user) }

    %w[guilded homepage discord twitch youtube].each do |field|
      it "strips protocol from #{field} url" do
        user.update(field => "https://foo.bar")
        user.reload

        expect(user.send(field)).to eq("foo.bar")
      end

      it "strips double slashes from #{field} url" do
        user.update(field => "//foo.bar")
        user.reload

        expect(user.send(field)).to eq("foo.bar")
      end

      it "strips http from #{field} url" do
        user.update(field => "http://foo.bar")
        user.reload

        expect(user.send(field)).to eq("foo.bar")
      end
    end
  end
end

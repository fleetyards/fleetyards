# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rails.app.creds integration" do
  it "provides Rails.app as alias for Rails.application" do
    expect(Rails.app).to eq(Rails.application)
  end

  it "provides creds accessor" do
    expect(Rails.app.creds).to be_a(RailsCredsBackport::CombinedConfiguration)
  end

  it "provides envs accessor" do
    expect(Rails.app.envs).to be_a(RailsCredsBackport::EnvConfiguration)
  end

  it "looks up ENV values through creds" do
    ENV["RAILS_CREDS_BACKPORT_TEST"] = "it_works"
    Rails.app.envs.reload
    # Reset creds so it picks up the reloaded envs
    Rails.app.creds = nil

    expect(Rails.app.creds.option(:rails_creds_backport_test)).to eq("it_works")
  ensure
    ENV.delete("RAILS_CREDS_BACKPORT_TEST")
    Rails.app.creds = nil
  end
end

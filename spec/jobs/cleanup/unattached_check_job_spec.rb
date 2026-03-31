# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cleanup::UnattachedCheckJob do
  describe "#perform" do
    it "purges unattached blobs older than 2 days" do
      blob = instance_double(ActiveStorage::Blob)
      scope = instance_double(ActiveRecord::Relation)

      allow(ActiveStorage::Blob).to receive(:unattached).and_return(scope)
      allow(scope).to receive(:where).and_return(scope)
      allow(scope).to receive(:find_each).and_yield(blob)
      allow(blob).to receive(:purge_later)

      described_class.new.perform

      expect(blob).to have_received(:purge_later)
    end
  end
end

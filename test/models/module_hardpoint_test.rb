# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: module_hardpoints
#
#  id              :uuid             not null, primary key
#  slot            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_id        :uuid
#  model_module_id :uuid
#
# Indexes
#
#  index_module_hardpoints_on_model_id_and_slot  (model_id,slot)
#
class ModuleHardpointTest < ActiveSupport::TestCase
  # A module's cached fragments are keyed on the module, and it embeds the ships
  # it is linked to -- so unlinking one has to move the module too.
  test "unlinking a ship moves the module's updated_at" do
    link = create(:module_hardpoint)
    model_module = link.model_module
    model_module.update_columns(updated_at: 1.day.ago)

    link.destroy!

    assert_operator model_module.reload.updated_at, :>, 1.minute.ago
  end
end

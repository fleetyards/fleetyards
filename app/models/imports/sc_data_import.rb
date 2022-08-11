# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id          :uuid             not null, primary key
#  aasm_state  :string
#  failed_at   :datetime
#  finished_at :datetime
#  info        :text
#  started_at  :datetime
#  type        :string
#  version     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module Imports
  class ScDataImport < ::Import
  end
end

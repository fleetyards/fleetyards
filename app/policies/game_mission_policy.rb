# frozen_string_literal: true

# The catalogue is public and its reads skip authorization entirely. Nothing
# here is a mission anybody owns, marks or edits -- every fact is replaced by
# the next load -- so there is no action left for a policy to decide.
class GameMissionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end
end

class ApplicationPolicy < ActionPolicy::Base
  authorize :user, allow_nil: true
end

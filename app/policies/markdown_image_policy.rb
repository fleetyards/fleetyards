# frozen_string_literal: true

class MarkdownImagePolicy < ApplicationPolicy
  def create?
    user.present?
  end

  params_filter do |params|
    params.permit(:file)
  end
end

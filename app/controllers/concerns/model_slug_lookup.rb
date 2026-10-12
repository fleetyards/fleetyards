# frozen_string_literal: true

# A model's page answers to its current slug, its RSI slug and the slug it had
# before a rename; the older two redirect to the current one.
module ModelSlugLookup
  extend ActiveSupport::Concern

  private def find_model_by_slug!(*includes, joins: nil)
    slug = params[:slug].downcase

    scope = Model.visible.active
    scope = scope.includes(*includes) if includes.any?
    scope = scope.joins(joins) if joins
    model = scope
      .where(slug:)
      .or(Model.where(rsi_slug: slug))
      .or(Model.where(legacy_slug: slug))
      .first!

    if model.slug != slug
      redirect_to url_for(slug: model.slug), status: :moved_permanently
      return model
    end

    model
  end
end

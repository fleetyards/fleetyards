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
    # A model's current slug wins over another one's former or RSI slug.
    model = scope
      .where(slug:)
      .or(scope.where(rsi_slug: slug))
      .or(scope.where(legacy_slug: slug))
      .order(Arel.sql(Model.sanitize_sql_array(["models.slug = ? DESC", slug])))
      .first!

    if model.slug != slug
      redirect_to url_for(slug: model.slug), status: :moved_permanently
      return model
    end

    model
  end
end

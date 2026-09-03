# frozen_string_literal: true

module Api
  module V1
    module Stats
      class BaseController < Api::BaseController
        skip_verify_authorized

        include ChartHelper

        # How far back a "trending" ship looks. Long enough that a quiet weekend
        # does not empty the chart, short enough that it still reads as now.
        TRENDING_WINDOW = 30.days

        before_action :authenticate_user!, only: []

        def quick_stats
          models = Model.visible.active
          total = models.count
          flight_ready = models.where(production_status: "flight-ready").count
          pledge_prices = models.where("pledge_price > 0").pluck(:pledge_price)
          lengths = models.where("models.length > 0").pluck(:length)

          ship_of_the_month_entry = Rollup.where(
            name: "Ship of the Month",
            interval: "month",
            time: Time.current.beginning_of_month
          ).first

          @quick_stats = {
            ships_count_year: models.year(Time.current.year).count,
            ships_count_total: total,
            manufacturer_count: Manufacturer.with_model.count,
            flight_ready_count: flight_ready,
            average_pledge_price: pledge_prices.any? ? (pledge_prices.sum / pledge_prices.size).to_i : 0,
            largest_ship: lengths.max&.to_f,
            smallest_ship: lengths.min&.to_f,
            vehicles_count: Vehicle.where(loaner: false, wanted: false).count,
            wishlists_count: Vehicle.where(wanted: true).count,
            ship_of_the_month: ship_of_the_month_entry&.dimensions&.dig("name"),
            ship_of_the_month_count: ship_of_the_month_entry&.value&.to_i || 0,
            painted_vehicles_percent: painted_vehicles_percent
          }
        end

        def trending_ships
          slug_views = Rollup
            .where(name: MetricsJob::ROLLUP_SHIP_VIEWS, interval: "day")
            .where(time: TRENDING_WINDOW.ago.beginning_of_day..)
            .group(Arel.sql("dimensions->>'model_slug'"))
            .sum(:value)

          # The rollup stores whatever sat in `/ships/<here>/`, and two of those
          # are routes rather than ships (`viewer`, `fleetchart`). Resolving each
          # slug through Model drops them, and drops a ship that has since been
          # hidden or retired along with them.
          names = Model.visible.active.where(slug: slug_views.keys).pluck(:slug, :name).to_h

          trending_ships = transform_for_bar_chart(
            slug_views.filter_map { |slug, views| [names[slug], views.to_i] if names.key?(slug) }.to_h
          ).take(10)

          render json: trending_ships.to_json
        end

        def most_wishlisted
          model_additions = Rollup
            .where(name: MetricsJob::ROLLUP_WISHLIST_BY_MODEL, interval: "month")
            .where(time: Time.current.beginning_of_month)
            .group(Arel.sql("dimensions->>'model_id'"))
            .sum(:value)

          names = Model.visible.active.where(id: model_additions.keys).pluck(:id, :name).to_h

          most_wishlisted = transform_for_bar_chart(
            model_additions.filter_map { |id, additions| [names[id], additions.to_i] if names.key?(id) }.to_h
          ).take(10)

          render json: most_wishlisted.to_json
        end

        # Which ships the build we are on changed the most.
        def patch_changes
          changed_facts = ModelBuildChange
            .for_build(::ScData::Source.environment, ::ScData::Source.version)
            .group(:model_id).count

          names = Model.visible.active.where(id: changed_facts.keys).pluck(:id, :name).to_h

          patch_changes = transform_for_bar_chart(
            changed_facts.filter_map { |id, changed| [names[id], changed] if names.key?(id) }.to_h
          ).take(10)

          render json: patch_changes.to_json
        end

        # Below this a model has too little of a hangar presence for a ratio to
        # mean anything: three owned and four wished is not demand, it is noise.
        # The tenth percentile of models holds 744, so this excludes only ships
        # nobody has rather than shaping the ranking.
        WISH_TO_OWN_FLOOR = 100

        # Share of hangared ships carrying a paint. Loaners are left out because
        # nobody chose their paint.
        private def painted_vehicles_percent
          hangared = Vehicle.visible.purchased.where(loaner: false)
          total = hangared.count
          return 0 if total.zero?

          (hangared.where.not(model_paint_id: nil).count * 100.0 / total).round(1)
        end

        # Standing demand, as opposed to `most_wishlisted`, which is the month's
        # additions. A ship can be heavily wanted for years and add nobody new.
        def wishlist_by_model
          wishlist_by_model = transform_for_bar_chart(
            Vehicle.visible.wanted.where(loaner: false)
                   .joins(:model)
                   .group("models.name").count
          ).take(10)

          render json: wishlist_by_model.to_json
        end

        # Wished against owned, which separates a ship people dream about from
        # one they simply have. Expressed per 100 owned so the figure stays an
        # integer and reads as a comparison rather than a rate.
        def wish_to_own_ratio
          counted = Vehicle.visible.where(loaner: false)
            .joins(:model)
            .group("models.name")
            .pluck(
              Arel.sql("models.name"),
              Arel.sql("COUNT(*) FILTER (WHERE vehicles.wanted)"),
              Arel.sql("COUNT(*) FILTER (WHERE NOT vehicles.wanted)")
            )

          wish_to_own_ratio = counted.filter_map do |name, wished, owned|
            next if owned < WISH_TO_OWN_FLOOR

            {label: name, count: (wished * 100.0 / owned).round, tooltip: name}
          end

          render json: wish_to_own_ratio.sort_by { |point| -point[:count] }.take(10).to_json
        end

        def top_paints
          paint_counts = Vehicle.visible.purchased.where(loaner: false)
            .where.not(model_paint_id: nil)
            .group(:model_paint_id).count

          names = ModelPaint.where(id: paint_counts.keys).includes(:model)
            .to_h { |paint| [paint.id, paint_label(paint)] }

          top_paints = transform_for_bar_chart(
            paint_counts.filter_map { |id, count| [names[id], count] if names.key?(id) }.to_h
          ).take(10)

          render json: top_paints.to_json
        end

        # A paint needs its ship named -- "Thundercloud" alone says nothing, and
        # paint names repeat across ships. But most of the ones that reach this
        # chart are already named after their ship, and `name_with_model` turns
        # those into "Carrack - Carrack Expedition", which then wraps onto two
        # lines to say the same word twice. Six of the eight most-used paints
        # are like that.
        private def paint_label(paint)
          model_name = paint.model&.name
          return paint.name if model_name.blank?
          return paint.name if paint.name.downcase.start_with?(model_name.downcase)

          "#{model_name} - #{paint.name}"
        end

        # How far back the pledge price chart reaches. Prices move on concept
        # sales and flyable releases, so a year is roughly one such cycle.
        PLEDGE_PRICE_WINDOW = 12.months

        # Net move per ship over the window: the oldest change's starting price
        # against the newest one's ending price.
        #
        # Only rows carrying both sides count. A ship first given a price, or one
        # whose price was taken away, has not moved -- and reading either as a
        # move from or to zero would put it straight to the top of the chart.
        def pledge_price_changes
          changes = ::PaperTrail::Version
            .where(item_type: "Model")
            .where(created_at: PLEDGE_PRICE_WINDOW.ago..)
            .where("object_changes -> 'pledge_price' ->> 0 IS NOT NULL")
            .where("object_changes -> 'pledge_price' ->> 1 IS NOT NULL")
            .order(:created_at)
            .pluck(
              :item_id,
              Arel.sql("(object_changes -> 'pledge_price' ->> 0)::numeric"),
              Arel.sql("(object_changes -> 'pledge_price' ->> 1)::numeric")
            )

          net = changes.each_with_object({}) do |(model_id, from, to), moves|
            moves[model_id] ||= {from:, to:}
            moves[model_id][:to] = to
          end

          names = Model.visible.active.where(id: net.keys).pluck(:id, :name).to_h

          pledge_price_changes = net.filter_map do |model_id, move|
            next unless names.key?(model_id)

            change = (move[:to] - move[:from]).round
            next if change.zero?

            {label: names[model_id], count: change, tooltip: names[model_id]}
          end

          # By size of the move, so the steepest cut ranks beside the steepest
          # rise rather than falling off the end. Both happen: 220 rises against
          # 161 cuts in what is recorded.
          render json: pledge_price_changes.sort_by { |point| -point[:count].abs }.take(10).to_json
        end

        # Grouped on `category`, not on the `component_class` this is named for.
        # That column is set on 333 of 8,739 components and `item_class` on 415,
        # so either one renders as a single "Unknown" slice covering 95% of the
        # chart. `category` is the taxonomy the catalogue actually filters on and
        # is set on 7,335 of them.
        def components_by_class
          components_by_class = transform_for_pie_chart(
            Component.group(:category).count
                .map { |label, count| {(label.present? ? I18n.t("filter.component.category.items.#{label}", default: label.titleize) : I18n.t("labels.unknown")) => count} }
                .reduce(:merge) || []
          )

          render json: components_by_class
        end

        def models_by_size
          models_by_size = transform_for_pie_chart(
            Model.visible.active
                 .group(:size).count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_size.to_json
        end

        def models_by_production_status
          models_by_production_status = transform_for_pie_chart(
            Model.visible.active
                 .group(:production_status).count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_production_status.to_json
        end

        def models_by_manufacturer
          models_by_manufacturer = transform_for_pie_chart(
            Manufacturer.with_model
                        .map { |m| {m.name => m.models.count} }
                        .reduce(:merge) || []
          )

          render json: models_by_manufacturer.to_json
        end

        def models_by_classification
          models_by_classification = transform_for_pie_chart(
            Model.visible.active
                 .group(:classification).count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_classification.to_json
        end

        def vehicles_by_model
          vehicles_by_model = transform_for_bar_chart(
            Vehicle.visible.where(loaner: false, wanted: false)
                   .joins(:model)
                   .group("models.name").count
          ).take(10)

          render json: vehicles_by_model.to_json
        end

        def ships_of_the_month
          ships_of_the_month = Rollup
            .where(name: "Ship of the Month", interval: "month")
            .where("time > ?", 1.year.ago)
            .order(time: :desc)
            .map do |entry|
              {
                label: "#{entry.dimensions["name"]} (#{I18n.l(entry.time.to_date, format: :month_year_short)})",
                count: entry.value.to_i,
                tooltip: "#{entry.dimensions["name"]} (#{I18n.l(entry.time.to_date, format: :month_year)})"
              }
            end

          render json: ships_of_the_month.to_json
        end

        def vehicles_per_month
          vehicles_per_month = Rollup.where("time > ?", 1.year.ago).series("Vehicle", interval: :month).map do |created_at, count|
            {
              label: I18n.l(created_at.to_date, format: :month_year_short),
              count:,
              tooltip: I18n.l(created_at.to_date, format: :month_year)
            }
          end

          render json: vehicles_per_month.to_json
        end

        def models_per_month
          models_per_month = Rollup.where("time > ?", 1.year.ago).series("Models", interval: :month).map do |created_at, count|
            {
              label: I18n.l(created_at.to_date, format: :month_year_short),
              count:,
              tooltip: I18n.l(created_at.to_date, format: :month_year)
            }
          end

          render json: models_per_month.to_json
        end
      end
    end
  end
end

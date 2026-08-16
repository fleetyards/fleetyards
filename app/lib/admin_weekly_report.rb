# frozen_string_literal: true

# Collects the numbers behind the weekly admin digest. Metrics come in two
# shapes: windowed ones counted over the reporting week and compared against the
# week before, and gauges that describe the state right now and have nothing to
# compare against.
class AdminWeeklyReport
  Metric = Struct.new(:key, :current, :previous, :format) do
    def delta
      return if previous.nil?

      current - previous
    end

    def comparable?
      !previous.nil?
    end
  end

  Section = Struct.new(:key, :metrics)

  LOWER_IS_BETTER = %i[failed_hangar_syncs failed_imports email_rejections ended_supporters].freeze

  def self.build
    new.build
  end

  def initialize(now: Time.current)
    @now = now
  end

  attr_reader :now

  def build
    {
      starts_at: current_range.begin,
      ends_at: current_range.end,
      sections: [growth, engagement, supporters, ops, content]
    }
  end

  private def current_range
    @current_range ||= (now - 1.week)...now
  end

  private def previous_range
    @previous_range ||= (now - 2.weeks)...(now - 1.week)
  end

  # Counts the same query over both windows so the template can render a delta.
  private def windowed(key, format: :integer, &counter)
    Metric.new(
      key:,
      current: counter.call(current_range),
      previous: counter.call(previous_range),
      format:
    )
  end

  private def gauge(key, value, format: :integer)
    Metric.new(key:, current: value, previous: nil, format:)
  end

  private def growth
    Section.new(
      key: :growth,
      metrics: [
        windowed(:registrations) { |range| User.where(created_at: range).count },
        windowed(:ships) { |range| Model.where(created_at: range).count },
        windowed(:vehicles) { |range| Vehicle.where(loaner: false, wanted: false, created_at: range).count },
        windowed(:wishes) { |range| Vehicle.where(loaner: false, wanted: true, created_at: range).count },
        windowed(:fleets) { |range| Fleet.where(created_at: range).count }
      ]
    )
  end

  private def engagement
    Section.new(
      key: :engagement,
      metrics: [
        windowed(:active_users) { |range| User.where(last_active_at: range).count },
        windowed(:visits) { |range| visits(range).count },
        windowed(:unique_visitors) { |range| visits(range).distinct.count(:visitor_token) },
        windowed(:fleet_memberships) { |range| FleetMembership.kept.where(created_at: range).count }
      ]
    )
  end

  private def supporters
    Section.new(
      key: :supporters,
      metrics: [
        windowed(:new_supporters) { |range| SupporterContribution.where(started_at: range).count },
        windowed(:supporter_amount, format: :currency) do |range|
          SupporterContribution.where(started_at: range).sum(:amount_cents)
        end,
        windowed(:ended_supporters) do |range|
          SupporterContribution.where(recurring: true, ended_at: range).count
        end
      ]
    )
  end

  private def ops
    Section.new(
      key: :ops,
      metrics: [
        windowed(:hangar_syncs) { |range| Imports::HangarSync.where(created_at: range).count },
        windowed(:failed_hangar_syncs) do |range|
          Imports::HangarSync.where(created_at: range, aasm_state: "failed").count
        end,
        windowed(:failed_imports) do |range|
          Import.where(created_at: range, aasm_state: "failed").where.not(type: "Imports::HangarSync").count
        end,
        windowed(:email_rejections) { |range| EmailRejection.where(created_at: range).count },
        gauge(:unresolved_rsi_blocks, RsiRequestLog.where(resolved: false).count)
      ]
    )
  end

  private def content
    Section.new(
      key: :content,
      metrics: [
        windowed(:star_citizen_updates) { |range| StarCitizenUpdate.where(created_at: range).count },
        gauge(:models_without_image, curatable_models.where.missing(:store_image_attachment).count),
        gauge(:models_without_price, curatable_models.where(player_ownable: true, pledge_price: nil).count),
        gauge(:models_need_position_curation, Model.where(positions_need_curation: true).count)
      ]
    )
  end

  private def visits(range)
    Ahoy::Visit.without_users(tracking_blocklist).where(started_at: range)
  end

  private def tracking_blocklist
    @tracking_blocklist ||= User.where(tracking: false).pluck(:id)
  end

  private def curatable_models
    Model.where(active: true, hidden: false)
  end
end

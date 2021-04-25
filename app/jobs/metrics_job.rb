# frozen_string_literal: true

class MetricsJob < ApplicationJob
  def perform
    User.rollup('Registrations', interval: 'month')
    User.rollup('Registrations', interval: 'year')
    Model.visible.active.rollup('Models', interval: 'month')
    Model.visible.active.rollup('Models', interval: 'year')
    Fleet.rollup('Fleet', interval: 'month')
    Fleet.rollup('Fleet', interval: 'year')
  end
end

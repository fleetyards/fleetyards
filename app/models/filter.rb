# frozen_string_literal: true

class Filter
  attr_accessor :category, :label, :value, :icon

  def initialize(options = {})
    @category = options[:category]
    @label = options[:label] || options[:name]
    @value = options[:value]
    @icon = options[:icon]
  end
end

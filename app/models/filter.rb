# frozen_string_literal: true

class Filter
  attr_accessor :category, :name, :value, :icon

  def initialize(options = {})
    @category = options[:category]
    @name = options[:name]
    @value = options[:value]
    @icon = options[:icon]
  end
end

# frozen_string_literal: true

class Filter
  attr_accessor :category, :name, :value

  def initialize(options = {})
    @category = options[:category]
    @name = options[:name]
    @value = options[:value]
  end
end

# frozen_string_literal: true
class Filter
  attr_accessor :resource, :field, :items, :translateable

  def initialize(options = {})
    @resource = options[:resource]
    @field = options[:field]
    @items = options[:items]
    @translateable = options[:translateable] || false
  end
end

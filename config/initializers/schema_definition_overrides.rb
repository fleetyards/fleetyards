# frozen_string_literal: true
module ActiveRecord
  module ConnectionAdapters #:nodoc:
    class TableDefinition
      def references(*args)
        options = args.extract_options!
        polymorphic = options.delete(:polymorphic)
        index_options = options.delete(:index)
        args.each do |col|
          column("#{col}_id", :uuid, options)
          column("#{col}_type", :string, polymorphic.is_a?(Hash) ? polymorphic : options) if polymorphic
          index(polymorphic ? %w(id type).map { |t| "#{col}_#{t}" } : "#{col}_id", index_options.is_a?(Hash) ? index_options : {}) if index_options
        end
      end
      alias belongs_to references
    end
  end
end

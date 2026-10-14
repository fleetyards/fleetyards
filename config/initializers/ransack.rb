Ransack.configure do |config|
  config.postgres_fields_sort_option = :nulls_always_last

  # Ransack 6 renders these as a case-sensitive LIKE, where 5.x rendered ILIKE
  # on PostgreSQL. Every search here, and the public API's `q[...Cont]`
  # filters, rely on the case-insensitive match.
  Ransack::Constants::DERIVED_PREDICATES.each do |name, options|
    next unless %w[cont not_cont start not_start end not_end].include?(name)

    config.add_predicate(name, options.merge(case_insensitive: true))
  end
end

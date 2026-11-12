# frozen_string_literal: true

# How the site search forgives what a reader types: a name matches spaced or
# not -- "northstar" is North Star, "f7cm" the F7C-M -- and, where nothing
# matches as typed, one a letter or two off -- "nortstar", "carack".
module SearchMatch
  # Letters and digits only, after lowercasing: what is left of a name once
  # however its maker spaced and punctuated it is set aside.
  COMPACT_SQL = "regexp_replace(lower(%s), '[^a-z0-9]+', '', 'g')"

  # Below this a query has too few trigrams for a near miss to mean anything:
  # "ore" is a letter off from half the catalogue.
  FUZZY_MIN_LENGTH = 4

  # Trigram word similarity, the better of the name as written and compacted.
  # "nortstar" scores 0.54 against North Star and 0.44 against Northern Lights;
  # a swapped pair, "mustnag", 0.5 against Mustang.
  FUZZY_THRESHOLD = 0.5

  module_function

  def compact(text)
    text.to_s.downcase.gsub(/[^a-z0-9]+/, "")
  end

  def compact_sql(column)
    format(COMPACT_SQL, column)
  end

  def fuzzy?(query)
    compact(query).length >= FUZZY_MIN_LENGTH
  end

  # Whether `column` is close enough to count. Word similarity scores the best
  # stretch of the name, so it also finds a name's middle -- and the inside of
  # a longer word: "carack" scores 0.71 against Tamarack.
  def fuzzy_match_sql(column)
    "GREATEST(word_similarity(:fuzzy, lower(#{column})), word_similarity(:fuzzy_compact, #{compact_sql(column)}))"
  end

  # How close it is, for the order: whole words only, so Carrack (0.67) comes
  # before Tamarack (0.33). Too harsh on a swapped pair to decide what counts,
  # and dearer, so it only orders the few that do.
  def fuzzy_rank_sql(column)
    "GREATEST(strict_word_similarity(:fuzzy, lower(#{column})), strict_word_similarity(:fuzzy_compact, #{compact_sql(column)}))"
  end

  def fuzzy_binds(query)
    {fuzzy: query.to_s.downcase, fuzzy_compact: compact(query)}
  end

  # Each of `texts` as [match, rank] against the query, in their order, from
  # the same functions the catalogue search uses.
  def fuzzy_scores(query, texts)
    return [] if texts.empty?

    sql = ActiveRecord::Base.sanitize_sql_array([
      "SELECT #{fuzzy_match_sql("t.text")}, #{fuzzy_rank_sql("t.text")} " \
      "FROM unnest(ARRAY[:texts]::text[]) WITH ORDINALITY AS t(text, position) ORDER BY t.position",
      {texts: texts.map(&:to_s), **fuzzy_binds(query)}
    ])

    ActiveRecord::Base.connection.select_rows(sql).map { |match, rank| [match.to_f, rank.to_f] }
  end
end

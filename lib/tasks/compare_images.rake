# frozen_string_literal: true

namespace :compare_images do
  desc "Populate share_key on existing CompareImage rows so future shares reuse them"
  # Existing rows have a versioned slug_set ("v2-<slugs joined by '-'>") from
  # OG-image generation but no share_key. Without this backfill, the first share
  # for an already-rendered comparison would either:
  #   (a) hit the runtime upgrade in CompareImage.find_for_share, which finds
  #       the existing row by slug_set and adds share_key in place, or
  #   (b) if the slugs aren't passed in canonical order, create a second row.
  # Backfilling lets share_key be looked up directly and saves the upgrade step.
  #
  # Slugs contain hyphens, so slug_set isn't reversible without a known-slug
  # lookup. This task greedy-matches known Model slugs against each slug_set;
  # rows it can't unambiguously decode are skipped (runtime upgrade still covers
  # them on the first share).
  task backfill_share_keys: :environment do
    style_prefix = "#{CompareImage::STYLE_VERSION}-"
    known_slugs = Model.pluck(:slug).sort_by { |s| -s.length }

    total = CompareImage.where(share_key: nil).count
    progress = 0
    updated = 0
    skipped = 0

    CompareImage.where(share_key: nil).find_each(batch_size: 500) do |record|
      progress += 1
      slug_set = record.slug_set.to_s
      bare = slug_set.start_with?(style_prefix) ? slug_set.sub(style_prefix, "") : slug_set
      next if bare.blank?

      matched = known_slugs.select { |s| bare.include?(s) }.sort
      next skipped += 1 if matched.empty?
      next skipped += 1 unless matched.join("-") == bare

      record.update!(share_key: matched.join(CompareImage::SHARE_KEY_SEPARATOR))
      updated += 1
    rescue ActiveRecord::RecordNotUnique
      skipped += 1
    end

    puts "compare_images:backfill_share_keys — processed #{progress}/#{total}, updated #{updated}, skipped #{skipped}"
  end
end

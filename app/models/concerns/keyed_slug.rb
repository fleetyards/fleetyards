# A unique slug for a game-file record whose name is routinely shared -- every
# ship with a manned turret contributes another "Manned Turret", and armour sets
# repeat a piece name across colourways. The default derivation is
# `name.parameterize` with nothing to break a tie. `sc_key` is the only field
# that separates them, and unlike a counter it survives a reload, so the URL a
# visitor bookmarked still resolves after the next patch.
#
# The backfill suffixes *every* member of a shared base, so the assignment does
# not depend on load order -- which row goes first differs between production
# and a restored dump. Afterwards the rule relaxes on purpose: a duplicate
# arriving in a later patch takes the suffix and the incumbent keeps the URL it
# already has, because re-slugging a page people have bookmarked is worse than
# the pair reading inconsistently. `slug_settled?` is what holds the incumbent
# still.
#
# Picking a free slug and writing it are separate statements, so two writers
# racing on the same new name can choose the same one. The unique index is the
# guarantee: the loser raises `RecordNotUnique` rather than quietly taking the
# other's URL. Not retried here -- a load is serial within a run, and the admin
# path would need two people renaming onto the same name in the same instant.
module KeyedSlug
  extend ActiveSupport::Concern

  private def update_slugs
    base = self.class.slug_for(name)
    return if slug_settled?(base)

    if base.blank?
      self.slug = nil
      return
    end

    self.slug = base
    return unless slug_base_shared? || slug_taken?

    if sc_key.present?
      self.slug = keyed_slug(base)
      return unless slug_taken?
    end

    suffix = 1
    loop do
      suffix += 1
      self.slug = "#{base}-#{suffix}"
      break unless slug_taken?
    end
  end

  # Whether the slug already reads as one this name would produce, which makes
  # the two existence checks below a pair of queries spent to rewrite the value
  # already in the column. A load saves every record it sees and renames a
  # handful.
  #
  # Deliberately *not* `will_save_change_to_name?`: `name` reads through to the
  # build, and `apply_build` writes that after the row is saved, so a rename
  # lands in the slug one save late. Comparing against the name the reader
  # gives now is what lets that catch up; keying off the column's own change
  # would freeze the stale slug for good.
  private def slug_settled?(base)
    return false unless persisted? && slug.present? && base.present?

    slug == base || slug == keyed_slug(base) || slug.match?(/\A#{Regexp.escape(base)}-\d+\z/)
  end

  private def keyed_slug(base)
    return if sc_key.blank?

    "#{base}-#{self.class.slug_for(sc_key.tr("_", "-"))}"
  end

  private def slug_base_shared?
    self.class.where(name:).where.not(id:).exists?
  end

  private def slug_taken?
    self.class.where(slug:).where.not(id:).exists?
  end
end

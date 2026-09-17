# frozen_string_literal: true

# `source` names the platform the money arrived on, and there are rows where
# nobody ever named one -- a payment typed in before the field meant this, or
# one whose platform the admin did not record.
#
# Until now those were forced to hold `other`, which the model documents as
# meaning both "a platform not listed here" and "a row nobody stated one for".
# Two facts in one value, and the second is the larger population: a supporter
# recording a Liberapay payment as `other` is saying something, and a row that
# was never touched is not.
#
# So the column loses its default and becomes nullable, and null is the answer
# for "unspecified". `other` keeps only its deliberate meaning.
class AllowUnspecifiedSupporterContributionSource < ActiveRecord::Migration[8.1]
  def up
    change_column_default :supporter_contributions, :source, from: "other", to: nil
    change_column_null :supporter_contributions, :source, true
  end

  def down
    change_column_null :supporter_contributions, :source, false, "other"
    change_column_default :supporter_contributions, :source, from: nil, to: "other"
  end
end

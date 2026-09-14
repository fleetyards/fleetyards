# frozen_string_literal: true

class AddPayerEmailToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    # The address the payment was made under, from whichever platform carried
    # it. Stored rather than resolved-and-discarded so a donor whose email had
    # no account yet is still found when they register later.
    add_column :supporter_contributions, :payer_email, :string
    add_index :supporter_contributions, :payer_email, where: "payer_email IS NOT NULL"
  end
end

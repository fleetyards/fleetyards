class AddAcceptLanguageToAhoyVisits < ActiveRecord::Migration[7.0]
  def change
    add_column :ahoy_visits, :accept_language, :string
  end
end

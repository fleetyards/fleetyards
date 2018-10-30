class CreateAffiliations < ActiveRecord::Migration[5.2]
  def change
    create_table :affiliations, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.references :affiliationable, polymorphic: true, type: :uuid, index: { name: 'index_affiliations_on_affiliationable' }
      t.references :faction, type: :uuid

      t.timestamps
    end
  end
end

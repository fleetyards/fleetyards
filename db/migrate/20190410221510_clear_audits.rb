class ClearAudits < ActiveRecord::Migration[5.2]
  def up
    Audited::Audit.destroy_all
  end

  def down
  end
end

class ResetScIdentifier < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE models SET sc_identifier = 'RSI_Polaris' WHERE sc_identifier = 'RSI_Polaris_FW';
      UPDATE models SET sc_identifier = NULL WHERE sc_identifier = 'AEGS_Idris';
    SQL
  end

  def down
    # no-op
  end
end

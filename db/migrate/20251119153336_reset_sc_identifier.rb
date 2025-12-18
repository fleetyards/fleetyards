class ResetScIdentifier < ActiveRecord::Migration[7.1]
  def change
    Model.where(sc_identifier: "RSI_Polaris_FW").first&.update(sc_identifier: "RSI_Polaris")
    Model.where(sc_identifier: "AEGS_Idris").first&.update(sc_identifier: nil)
  end
end

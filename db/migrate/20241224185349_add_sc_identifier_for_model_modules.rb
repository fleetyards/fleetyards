class AddScIdentifierForModelModules < ActiveRecord::Migration[7.1]
  def up
    ModelModule.find_by(name: "Front Cargo Module")&.update(sc_key: "AEGS_Retaliator_Module_Front_Cargo")
    ModelModule.find_by(name: "Front Torpedo Bay")&.update(sc_key: "AEGS_Retaliator_Module_Front_Bomber")
    ModelModule.find_by(name: "Rear Cargo Module")&.update(sc_key: "AEGS_Retaliator_Module_Rear_Cargo")
    ModelModule.find_by(name: "Rear Torpedo Bay")&.update(sc_key: "AEGS_Retaliator_Module_Rear_Bomber")
  end
end

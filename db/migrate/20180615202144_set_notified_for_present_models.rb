class SetNotifiedForPresentModels < ActiveRecord::Migration[5.2]
  def change
    Model.update_all(notified: true)
  end
end

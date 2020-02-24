class AddTrackingSignalToComponents < ActiveRecord::Migration[6.0]
  def change
    add_column :components, :tracking_signal, :integer
  end
end

class CreateMessageAttachments < ActiveRecord::Migration[6.1]
  def change
    create_table :message_attachments, id: :uuid do |t|
      t.binary :payload
      t.uuid :message_id

      t.timestamps
    end
  end
end

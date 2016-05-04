class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.string :sender
      t.string :receiver
      t.string :subject
      t.text :actual_body
      t.text :body_html

      t.timestamps null: false
    end
  end
end

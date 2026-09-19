class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.string :time_zone, null: false
      t.string :public_token, null: false

      t.timestamps
    end

    add_index :events, :public_token, unique: true
  end
end

class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name
      t.text :description
      t.string :time_zone
      t.string :public_token

      t.timestamps
    end
  end
end

class CreateResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :responses do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name
      t.string :time_zone
      t.text :comment

      t.timestamps
    end
  end
end

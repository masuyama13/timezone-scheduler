class CreateEventCities < ActiveRecord::Migration[8.1]
  def change
    create_table :event_cities do |t|
      t.references :event, null: false, foreign_key: true
      t.string :city_key, null: false
      t.string :name, null: false
      t.string :region, null: false
      t.string :time_zone, null: false
      t.boolean :is_primary, null: false, default: false

      t.timestamps
    end

    add_index :event_cities, [ :event_id, :city_key ], unique: true
  end
end

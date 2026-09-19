class CreateTimeOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :time_options do |t|
      t.references :event, null: false, foreign_key: true
      t.datetime :starts_at

      t.timestamps
    end
  end
end

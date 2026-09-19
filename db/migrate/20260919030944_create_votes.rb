class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :response, null: false, foreign_key: true
      t.references :time_option, null: false, foreign_key: true
      t.boolean :available, null: false

      t.timestamps
    end
  end
end

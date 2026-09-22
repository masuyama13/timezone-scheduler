class ChangeVoteAvailabilityToEnum < ActiveRecord::Migration[8.1]
  def up
    rename_column :votes, :available, :availability
    change_column :votes, :availability, :integer, null: false,
      using: "CASE WHEN availability THEN 1 ELSE 0 END"
  end

  def down
    change_column :votes, :availability, :boolean, null: false,
      using: "(availability = 1)"
    rename_column :votes, :availability, :available
  end
end

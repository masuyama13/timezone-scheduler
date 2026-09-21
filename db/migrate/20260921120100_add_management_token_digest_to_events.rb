class AddManagementTokenDigestToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :management_token_digest, :string
    add_index :events, :management_token_digest, unique: true
  end
end

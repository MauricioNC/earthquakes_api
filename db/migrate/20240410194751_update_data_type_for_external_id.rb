class UpdateDataTypeForExternalId < ActiveRecord::Migration[7.1]
  def change
    change_column :features, :external_id, :string
  end
end

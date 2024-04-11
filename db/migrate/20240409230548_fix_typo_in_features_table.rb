class FixTypoInFeaturesTable < ActiveRecord::Migration[7.1]
  def change
    rename_column :features, :tusunami, :tsunami
  end
end

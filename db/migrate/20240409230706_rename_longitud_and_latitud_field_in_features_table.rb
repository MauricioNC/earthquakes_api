class RenameLongitudAndLatitudFieldInFeaturesTable < ActiveRecord::Migration[7.1]
  def change
    rename_column :features, :longitud, :longitude
    rename_column :features, :latitud, :latitude
  end
end

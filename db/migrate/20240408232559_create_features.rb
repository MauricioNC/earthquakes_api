class CreateFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :features do |t|
      t.integer :external_id
      t.integer :magnitude
      t.string :place, null: false
      t.timestamp :time
      t.string :url, null: false
      t.integer :tusunami
      t.string :magType, null: false
      t.string :title, null: false
      t.decimal :longitud, null: false
      t.decimal :latitud, null: false

      t.timestamps
    end
  end
end

class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name
      t.decimal :price
      t.integer :sku
      t.string :active
      t.date :date_added

      t.timestamps
    end
  end
end

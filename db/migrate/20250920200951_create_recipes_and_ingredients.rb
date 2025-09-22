class CreateRecipesAndIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.integer :cook_time
      t.integer :prep_time
      t.float :ratings
      t.string :category
      t.string :meal_type
      t.string :author
      t.string :image_url
      t.timestamps
    end

    create_table :ingredients do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :ingredients, :name, unique: true

    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true

      t.string :raw_text # full original string from JSON
      t.float :quantity  # parsed numeric quantity
      t.string :unit     # standardized unit (cup, tbsp, clove, etc.)

      t.timestamps
    end
  end
end

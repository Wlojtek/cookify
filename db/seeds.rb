# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'json'

FRACTION_MAP = {
  "¼" => 0.25,
  "½" => 0.5,
  "¾" => 0.75,
  "⅓" => 1.0/3,
  "⅔" => 2.0/3,
  "⅛" => 0.125
}


def fraction_to_float(str)
  return nil unless str
  str = str.strip

  # Unicode fraction alone
  return FRACTION_MAP[str] if FRACTION_MAP[str]

  # Mixed number: e.g., "1 ½"
  if str =~ /^(\d+)\s+([¼½¾⅓⅔⅛])$/
    return $1.to_f + FRACTION_MAP[$2]
  end

  # Plain number
  str.to_f
end

def parse_ingredient(line)
  # Regex updated to support mixed numbers, unicode fractions, decimals
  match = line.match(
    /
      (?<quantity>[\d¼½¾⅓⅔⅛\/\.]+\s*[\d¼½¾⅓⅔⅛]*)?   # quantity: number, fraction, mixed number
      \s*
      (?<unit>[a-zA-Z]+)?                             # unit
      \s*
      (?<ingredient>.+?)                               # ingredient
    /x
  )

  return nil unless match

  {
    quantity: fraction_to_float(match[:quantity]),
    unit: match[:unit]&.downcase,
    ingredient: match[:ingredient]&.downcase&.strip,
  }
end

# --- Load JSON data ---
file_path = Rails.root.join("db", "recipes-en.json")
recipes_data = JSON.parse(File.read(file_path))

puts "Seeding #{recipes_data.size} recipes..."

recipes_data.each do |r|
  recipe = Recipe.create!(
    title: r["title"],
    cook_time: r["cook_time"],
    prep_time: r["prep_time"],
    ratings: r["ratings"],
    cuisine: r["cuisine"],
    category: r["category"],
    author: r["author"],
    image_url: r["image"],
    instructions: r["instructions"] || ""
  )

  r["ingredients"].each do |line|
    parsed = parse_ingredient(line)

    # Skip if ingredient parsing fails
    next unless parsed[:ingredient].present?

    ingredient = Ingredient.find_or_create_by!(name: parsed[:ingredient])

    RecipeIngredient.create!(
      recipe: recipe,
      ingredient: ingredient,
      raw_text: line,
      quantity: parsed[:quantity],
      unit: parsed[:unit],
      preparation: parsed[:preparation]
    )
  end
end

puts "✅ Done seeding!"
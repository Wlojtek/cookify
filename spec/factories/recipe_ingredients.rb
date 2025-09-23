FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    raw_text { "1 cup flour" }
    quantity { 1.0 }
    unit { "cup" }
  end
end
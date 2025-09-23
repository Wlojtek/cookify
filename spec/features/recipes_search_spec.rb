require 'rails_helper'

RSpec.feature "Recipes search", type: :feature do
  let!(:flour) { create(:ingredient, name: "flour") }
  let!(:sugar) { create(:ingredient, name: "sugar") }
  let!(:eggs) { create(:ingredient, name: "eggs") }
  let!(:butter) { create(:ingredient, name: "butter") }

  let!(:full_match_recipe) do
    recipe = create(:recipe, title: "Full Match Cake", ratings: 5.0, category: "Dessert")
    create(:recipe_ingredient, recipe: recipe, ingredient: flour, raw_text: "2 cups flour")
    create(:recipe_ingredient, recipe: recipe, ingredient: sugar, raw_text: "1 cup sugar")
    recipe
  end

  let!(:partial_match_recipe) do
    recipe = create(:recipe, title: "Partial Match Bread", ratings: 4.0, category: "Bread")
    create(:recipe_ingredient, recipe: recipe, ingredient: flour, raw_text: "3 cups flour")
    create(:recipe_ingredient, recipe: recipe, ingredient: butter, raw_text: "1/2 cup butter")
    recipe
  end

  let!(:partial_match_recipe_1) do
    recipe = create(:recipe, title: "Partial Match Bread 2", ratings: 4.0, category: "Bread")
    create(:recipe_ingredient, recipe: recipe, ingredient: flour, raw_text: "3 cups flour")
    create(:recipe_ingredient, recipe: recipe, ingredient: butter, raw_text: "1/2 cup butter")
    create(:recipe_ingredient, recipe: recipe, ingredient: butter, raw_text: "1/3 cup butter")
    create(:recipe_ingredient, recipe: recipe, ingredient: butter, raw_text: "1/3 cup sugar")
    recipe
  end

  let!(:no_match_recipe) do
    recipe = create(:recipe, title: "No Match Salad", ratings: 3.0, category: "Salad")
    create(:recipe_ingredient, recipe: recipe, ingredient: butter, raw_text: "2 tbsp butter")
    recipe
  end

  scenario "searching for recipes with ingredients" do
    visit recipes_path

    fill_in "ingredients", with: "flour, sugar"
    fill_in "total_time", with: "60"
    click_button "Search"

    expect(page).to have_content("Recipes that only use ingredients from your fridge:")

    within "#fully-match-recipes" do
      expect(page).to have_content("Full Match Cake")
      expect(page).to have_content("5.0") # ratings
    end

    expect(page).to have_content("Most Cookable Meal recipes (at least one ingredient matched):")

    within "#partially-match-recipes" do
      expect(page).to have_content("Partial Match Bread")
      expect(page).to have_content("4.0") # ratings
      expect(page).not_to have_content("No Match Salad")
    end
  end

  scenario "sorting partial matches by matched ingredients" do
    high_match_recipe = create(:recipe, title: "High Match Pie", ratings: 4.5, category: "Dessert")
    create(:recipe_ingredient, recipe: high_match_recipe, ingredient: flour, raw_text: "1 cup flour")
    create(:recipe_ingredient, recipe: high_match_recipe, ingredient: sugar, raw_text: "2 cups sugar")
    create(:recipe_ingredient, recipe: high_match_recipe, ingredient: eggs, raw_text: "3 eggs")

    visit recipes_path

    fill_in "ingredients", with: "flour, sugar, eggs"
    click_button "Search"

    click_link "Matched"

    within "#partially-match-recipes tbody" do
      rows = all('tr')
      expect(rows[1]).to have_content("Partial Match Bread 2")
      expect(rows[0]).to have_content("Partial Match Bread")
    end
  end
end
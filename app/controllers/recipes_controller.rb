class RecipesController < ApplicationController
  def index
    base_query = Recipe.all
    if params[:total_time].present?
      total_time = params[:total_time].to_i
      base_query = base_query.where('prep_time + cook_time <= ?', total_time)
    end

    if params[:ingredients].present?
      user_ingredients = parse_ingredients(params[:ingredients])

      user_ingredients_downcase = user_ingredients.map(&:downcase)

      # Build WHERE clause using raw_text from recipe_ingredients
      conditions = user_ingredients_downcase.map { |i| "lower(recipe_ingredients.raw_text) LIKE ?" }.join(" OR ")
      like_values = user_ingredients_downcase.map { |i| "%#{i}%" }

      recipes_only_user_ingredients = base_query.joins(:recipe_ingredients)
        .group("recipes.id")
        .having("SUM(CASE WHEN NOT (#{conditions}) THEN 1 ELSE 0 END) = 0", *like_values)
        .order(ratings: :desc)

      recipes_partial_match = base_query.joins(:recipe_ingredients)
        .where(conditions, *like_values)
        .where.not(id: recipes_only_user_ingredients.select(:id))
        .distinct
        .order(ratings: :desc)

      @recipes_only_user_ingredients = recipes_only_user_ingredients || []
      @recipes_partial_match = recipes_partial_match || []
    else
      @recipes_only_user_ingredients = base_query.order(ratings: :desc)
      @recipes_partial_match = []
    end
  end

  def show
    @recipe = Recipe.find(params[:id])
  end

  private

  def recipe_params
    params.permit(:ingredients, :total_time)
  end

  def parse_ingredients(input)
    input.split(',').map do |item|
      item.strip.split.first
    end
  end
end

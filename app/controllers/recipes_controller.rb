class RecipesController < ApplicationController
  def index
    base_query = Recipe.all
    base_query = filter_by_time(base_query)

    if params[:ingredients].present?
      user_ingredients = parse_ingredients(params[:ingredients])
      search_service = RecipeSearchService.new
      conditions, like_values = search_service.build_ingredient_conditions(user_ingredients)

      @recipes_only_user_ingredients = search_service.find_full_matching_recipes(base_query, conditions, like_values)
      @recipes_partial_match = search_service.find_partial_matching_recipes(base_query, conditions, like_values, params[:sort_by])
    else
      @recipes_only_user_ingredients = []
      @recipes_partial_match = []
    end
  end

  def show
    @recipe = Recipe.find(params[:id])
  end

  private

  def recipe_params
    params.permit(:ingredients, :total_time, :sort_by, :direction)
  end

  def parse_ingredients(input)
    input.split(",").map do |item|
      item.strip.split.first
    end
  end

  def filter_by_time(query)
    if params[:total_time].present?
      total_time = params[:total_time].to_i
      query.where("prep_time + cook_time <= ?", total_time)
    else
      query
    end
  end
end

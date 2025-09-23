class RecipeSearchService
  def build_ingredient_conditions(user_ingredients)
    user_ingredients_downcase = user_ingredients.map(&:downcase)
    conditions = user_ingredients_downcase.map { |i| "lower(recipe_ingredients.raw_text) LIKE ?" }.join(" OR ")
    like_values = user_ingredients_downcase.map { |i| "%#{i}%" }
    [conditions, like_values]
  end

  def find_full_matching_recipes(query, conditions, like_values)
    like_conditions = build_like_conditions(like_values)

    query.joins(:recipe_ingredients)
      .group("recipes.id")
      .having("SUM(CASE WHEN NOT (#{conditions}) THEN 1 ELSE 0 END) = 0", *like_values)
      .select(
        "recipes.*,
         COUNT(DISTINCT recipe_ingredients.id) AS total_ingredients,
         COUNT(DISTINCT recipe_ingredients.id) AS matched_ingredients,
         0 AS missing_ingredients"
      )
      .order(ratings: :desc)
  end

  def find_partial_matching_recipes(query, conditions, like_values, sort_by)
    like_conditions = build_like_conditions(like_values)

    subquery = query.joins(:recipe_ingredients)
      .group("recipes.id")
      .select(
        "recipes.*,
         COUNT(DISTINCT recipe_ingredients.id) AS total_ingredients,
         SUM(CASE WHEN (#{like_conditions}) THEN 1 ELSE 0 END) AS matched_ingredients,
         (COUNT(DISTINCT recipe_ingredients.id) - SUM(CASE WHEN (#{like_conditions}) THEN 1 ELSE 0 END)) AS missing_ingredients"
      )

    order_clause = build_order_clause(sort_by)

    query
      .from("(#{subquery.to_sql}) AS recipes_with_counts")
      .select("recipes_with_counts.*,
               (abs(matched_ingredients - missing_ingredients)) AS score")
      .where("matched_ingredients > 0")
      .where("missing_ingredients > 0")
      .order(order_clause)
      .limit(50)
  end

  private

  def build_like_conditions(like_values)
    like_values
      .map { |i| "lower(recipe_ingredients.raw_text) LIKE " + ActiveRecord::Base.connection.quote("%#{i}%") }
      .join(" OR ")
  end

  def build_order_clause(sort_by)
    case sort_by
    when "matched"
      "matched_ingredients DESC"
    when "missing"
      "missing_ingredients ASC"
    when "rank"
      "ratings DESC"
    else
      "score asc"
    end
  end
end
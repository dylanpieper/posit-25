# tidymodels classification with iris dataset
# demonstrates predictions and probabilities for new examples

# load required libraries
library(tidymodels)
library(dplyr)
library(cli)

# load the iris dataset (built into r)
data(iris)

# set seed for reproducibility
set.seed(123)

# split the data into training and testing sets
iris_split <- initial_split(iris, prop = 0.75, strata = Species)
iris_train <- training(iris_split)
iris_test <- testing(iris_split)

cli_alert_info("training: {nrow(iris_train)} | testing: {nrow(iris_test)}")

# create a recipe for preprocessing
iris_recipe <- recipe(Species ~ ., data = iris_train) |>
  step_normalize(all_predictors()) |> # normalize all predictor variables
  step_corr(all_predictors(), threshold = 0.9) # remove highly correlated predictors

# specify the model - using random forest
rf_spec <- rand_forest(
  mtry = tune(),
  trees = 1000,
  min_n = tune()
) |>
  set_engine("ranger", importance = "impurity") |>
  set_mode("classification")

# create a workflow
iris_workflow <- workflow() |>
  add_recipe(iris_recipe) |>
  add_model(rf_spec)

# create cross-validation folds for tuning
iris_folds <- vfold_cv(iris_train, v = 5, strata = Species)

# tune hyperparameters
rf_grid <- grid_regular(
  mtry(range = c(1, 3)), # adjusted for 3 predictors after preprocessing
  min_n(range = c(5, 20)),
  levels = 3
)

# perform tuning
tune_results <- iris_workflow |>
  tune_grid(
    resamples = iris_folds,
    grid = rf_grid
  )

# select best parameters
best_params <- select_best(tune_results, metric = "accuracy")

# finalize the workflow with best parameters
final_workflow <- iris_workflow |>
  finalize_workflow(best_params)

# fit the final model
final_fit <- final_workflow |>
  fit(data = iris_train)

# make predictions on test set
test_predictions <- final_fit |>
  predict(new_data = iris_test) |>
  bind_cols(final_fit |> predict(new_data = iris_test, type = "prob")) |>
  bind_cols(iris_test |> select(Species))

# create new example data
new_examples <- tibble(
  Sepal.Length = c(5.1, 6.2, 7.3, 4.8, 5.9),
  Sepal.Width = c(3.5, 2.9, 2.8, 3.0, 3.2),
  Petal.Length = c(1.4, 4.3, 6.3, 1.6, 4.8),
  Petal.Width = c(0.2, 1.3, 1.8, 0.2, 1.8)
)

# make predictions on new examples
new_predictions <- final_fit |>
  predict(new_data = new_examples) |>
  bind_cols(final_fit |> predict(new_data = new_examples, type = "prob")) |>
  bind_cols(new_examples)

new_predictions

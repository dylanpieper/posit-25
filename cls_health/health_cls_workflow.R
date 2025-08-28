# tidymodels classification with symptom2disease dataset
# demonstrates predictions and probabilities for disease classification

# load required libraries
library(tidymodels)
library(textrecipes)
library(stopwords)
library(dplyr)
library(cli)
library(readr)

# load the symptom2disease dataset
health_data <- read_csv("cls_health/Symptom2Disease.csv") |>
  mutate(label = as.factor(label))

# set seed for reproducibility
set.seed(123)

# split the data into training, validation, and testing sets
health_split <- initial_split(health_data, prop = 0.6, strata = label)
health_train <- training(health_split)
health_temp <- testing(health_split)

# split the remaining 40% into validation (20%) and test (20%)
val_test_split <- initial_split(health_temp, prop = 0.5, strata = label)
health_val <- training(val_test_split)
health_test <- testing(val_test_split)

cli_alert_info("training: {nrow(health_train)} | validation: {nrow(health_val)} | testing: {nrow(health_test)}")

# create a recipe for preprocessing
health_recipe <- recipe(label ~ text, data = health_train) |>
  step_tokenize(text) |>
  step_stopwords(text) |>
  step_tokenfilter(text, max_tokens = 500) |>
  step_tfidf(text)

# specify the model - using random forest
rf_spec <- rand_forest(
  mtry = tune(),
  trees = 1000,
  min_n = tune()
) |>
  set_engine("ranger", importance = "impurity") |>
  set_mode("classification")

# create a workflow
health_workflow <- workflow() |>
  add_recipe(health_recipe) |>
  add_model(rf_spec)

# create cross-validation folds for tuning
health_folds <- vfold_cv(health_train, v = 5, strata = label)

# tune hyperparameters
rf_grid <- grid_regular(
  mtry(range = c(10, 50)),
  min_n(range = c(5, 20)),
  levels = 3
)

# perform tuning
tune_results <- health_workflow |>
  tune_grid(
    resamples = health_folds,
    grid = rf_grid
  )

# select best parameters
best_params <- select_best(tune_results, metric = "accuracy")

# finalize the workflow with best parameters
final_workflow <- health_workflow |>
  finalize_workflow(best_params)

# fit the final model on training data
final_fit <- final_workflow |>
  fit(data = health_train)

# evaluate on validation set
val_predictions <- final_fit |>
  predict(new_data = health_val) |>
  bind_cols(health_val |> select(label))

val_accuracy <- val_predictions |>
  accuracy(truth = label, estimate = .pred_class)

cli_alert_success("validation accuracy: {round(val_accuracy$.estimate, 3)}")

# make predictions on test set
test_predictions <- final_fit |>
  predict(new_data = health_test) |>
  bind_cols(final_fit |> predict(new_data = health_test, type = "prob")) |>
  bind_cols(health_test |> select(label, text))

# calculate test accuracy
test_accuracy <- test_predictions |>
  accuracy(truth = label, estimate = .pred_class)

cli_alert_success("test accuracy: {round(test_accuracy$.estimate, 3)}")

# create new example symptom descriptions
new_examples <- tibble(
  text = c(
    "I have a persistent cough and fever for the past three days",
    "My joints are aching and I have red patches on my skin that are very itchy",
    "I feel very tired and have noticed small pits in my fingernails",
    "There are scaly patches on my elbows and knees that keep flaking off",
    "I have difficulty breathing and chest pain when I exercise"
  )
)

# make predictions on new examples
new_predictions <- final_fit |>
  predict(new_data = new_examples) |>
  bind_cols(final_fit |> predict(new_data = new_examples, type = "prob")) |>
  bind_cols(new_examples)

new_predictions

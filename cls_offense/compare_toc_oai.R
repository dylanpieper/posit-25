library(tidyverse)

# load toc data
toc <- openxlsx::readWorkbook("cls_offense/cjars_toc.xlsx", sheet = 2)
toc_uccs <- openxlsx::readWorkbook("cls_offense/cjars_toc.xlsx", sheet = 3)

# load openai data
oai_dat <- utils::read.csv("cls_offense/oai_dat.csv") |>
  dplyr::relocate(description)

# join toc data with uccs codes
toc_processed <- toc |>
  dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, 3))) |>
  dplyr::left_join(toc_uccs, by = "uccs_code") |>
  dplyr::mutate(
    description = stringr::str_squish(description),
    charge_desc = tolower(charge_desc),
    offense_type_desc = tolower(offense_type_desc)
  ) |>
  dplyr::select(description, toc_offense_category = charge_desc, toc_offense_type = offense_type_desc, probability)

# process openai data
oai_processed <- oai_dat |>
  dplyr::mutate(description = stringr::str_squish(description)) |>
  dplyr::select(description,
    openai_offense_category = offense_category,
    openai_offense_type = offense_type, uncertainty_score
  )

# create review dataset
review <- toc_processed |>
  dplyr::left_join(oai_processed, by = "description") |>
  dplyr::mutate(
    both_confident = probability >= 0.8 & uncertainty_score <= 0.2,
    agreement = toc_offense_type == openai_offense_type,
    review_needed = dplyr::case_when(
      both_confident & !agreement ~ "yes_disagree_certain",
      !both_confident & !agreement ~ "yes_disagree_uncertain",
      TRUE ~ "no_agree"
    ),
    toc_confidence = probability,
    openai_confidence = 1 - uncertainty_score
  ) |>
  dplyr::select(
    description,
    toc_offense_category,
    openai_offense_category,
    toc_offense_type,
    openai_offense_type,
    agreement,
    review_needed,
    toc_confidence,
    openai_confidence
  )

cli::cli_inform("Agreement rate: {scales::percent(mean(review$agreement, na.rm = TRUE))}")

View(review |> filter(!agreement))

# review patterns for "Animal" cruelty and "IDSI" sexual abuse

# toc fails to classify most animal abuse as violent
review_animal <- review |>
  filter(stringr::str_detect(description, "Animal"))

# toc fails to classify some IDSI as violent
review_idsi <- review |>
  filter(stringr::str_detect(description, "IDSI"))

View(review_animal)
View(review_idsi)

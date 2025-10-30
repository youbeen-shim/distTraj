# ============================================================================
# ALL POSSIBLE FLEXMIX APPROACHES FOR LONGITUDINAL TRAJECTORY MODELING
# ============================================================================
# Testing every documented method to find what works

library(tidyverse)
library(flexmix)

# Assume you have test_data (long format) and wide_data already created
# test_data: patient_id, time, hospital_visits (100 patients × 20 quarters)
# wide_data: patient_id, t0, t1, ..., t19 (100 rows)

# ============================================================================
# APPROACH 1: Long format with | grouping [MOST LIKELY TO WORK]
# ============================================================================
# Based on: flexmix examples, Andrew Wheeler blog, longmixr package
# Success likelihood: 85%

cat("=== APPROACH 1: Long format with | operator ===\n")
approach1 <- tryCatch({
  flexmix(
    hospital_visits ~ time + I(time^2) | patient_id,
    data = test_data,
    k = 4,
    model = FLXMRglm(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach1)) {
  post_rows <- nrow(posterior(approach1))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach1_valid <- !is.null(approach1) && nrow(posterior(approach1)) == 100

# ============================================================================
# APPROACH 2: Long format with explicit factor(patient_id)
# ============================================================================
# Sometimes the factor conversion needs to be explicit in formula
# Success likelihood: 75%

cat("=== APPROACH 2: Explicit factor in formula ===\n")
approach2 <- tryCatch({
  flexmix(
    hospital_visits ~ time + I(time^2) | factor(patient_id),
    data = test_data,
    k = 4,
    model = FLXMRglm(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach2)) {
  post_rows <- nrow(posterior(approach2))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach2_valid <- !is.null(approach2) && nrow(posterior(approach2)) == 100

# ============================================================================
# APPROACH 3: Long format with . ~ . | id syntax
# ============================================================================
# Alternative formula syntax from flexmix documentation
# Success likelihood: 70%

cat("=== APPROACH 3: Dot formula with | id ===\n")
approach3 <- tryCatch({
  # Create temporary dataset with just needed columns
  temp_data <- test_data %>%
    dplyr::select(patient_id, time, hospital_visits) %>%
    mutate(time2 = time^2)
  
  flexmix(
    hospital_visits ~ time + time2 | patient_id,
    data = temp_data,
    k = 4,
    model = FLXMRglm(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach3)) {
  post_rows <- nrow(posterior(approach3))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach3_valid <- !is.null(approach3) && nrow(posterior(approach3)) == 100

# ============================================================================
# APPROACH 4: Wide format with as.matrix()
# ============================================================================
# Convert time series to matrix format
# Success likelihood: 60%

cat("=== APPROACH 4: Wide format with matrix ===\n")
approach4 <- tryCatch({
  # Extract time series columns as matrix
  time_matrix <- wide_data %>%
    dplyr::select(starts_with("t")) %>%
    as.matrix()
  
  rownames(time_matrix) <- wide_data$patient_id
  
  flexmix(
    time_matrix ~ 1,
    k = 4,
    model = FLXMRglm(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach4)) {
  post_rows <- nrow(posterior(approach4))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach4_valid <- !is.null(approach4) && nrow(posterior(approach4)) == 100

# ============================================================================
# APPROACH 5: Long format with FLXMRglmfix (fixed/varying coefficients)
# ============================================================================
# Use glmfix driver which handles nested models better
# Success likelihood: 50%

cat("=== APPROACH 5: FLXMRglmfix with nested ===\n")
approach5 <- tryCatch({
  flexmix(
    hospital_visits ~ time + I(time^2) | patient_id,
    data = test_data,
    k = 4,
    model = FLXMRglmfix(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach5)) {
  post_rows <- nrow(posterior(approach5))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach5_valid <- !is.null(approach5) && nrow(posterior(approach5)) == 100

# ============================================================================
# APPROACH 6: Aggregate to patient level first
# ============================================================================
# Manually aggregate before flexmix (defeats purpose but might work)
# Success likelihood: 40%

cat("=== APPROACH 6: Pre-aggregate patient summaries ===\n")
approach6 <- tryCatch({
  # Create patient-level summary features
  patient_summary <- test_data %>%
    group_by(patient_id) %>%
    summarise(
      mean_visits = mean(hospital_visits),
      max_visits = max(hospital_visits),
      total_visits = sum(hospital_visits),
      slope = coef(lm(hospital_visits ~ time))[2],
      .groups = "drop"
    )
  
  flexmix(
    cbind(mean_visits, max_visits, total_visits, slope) ~ 1,
    data = patient_summary,
    k = 4,
    model = list(
      FLXMRglm(family = "gaussian"),
      FLXMRglm(family = "gaussian"),
      FLXMRglm(family = "gaussian"),
      FLXMRglm(family = "gaussian")
    ),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach6)) {
  post_rows <- nrow(posterior(approach6))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Note: This doesn't model trajectories directly!\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach6_valid <- !is.null(approach6) && nrow(posterior(approach6)) == 100

# ============================================================================
# APPROACH 7: Use stepFlexmix wrapper
# ============================================================================
# stepFlexmix sometimes handles longitudinal data better
# Success likelihood: 65%

cat("=== APPROACH 7: stepFlexmix wrapper ===\n")
approach7 <- tryCatch({
  result <- stepFlexmix(
    hospital_visits ~ time + I(time^2) | patient_id,
    data = test_data,
    k = 4,
    model = FLXMRglm(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 500, verbose = 0),
    nrep = 1  # Just 1 rep for testing
  )
  
  getModel(result, which = "BIC")
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach7)) {
  post_rows <- nrow(posterior(approach7))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach7_valid <- !is.null(approach7) && nrow(posterior(approach7)) == 100

# ============================================================================
# APPROACH 8: Manually reshape and use simple regression mixture
# ============================================================================
# Last resort: treat each time point separately
# Success likelihood: 30%

cat("=== APPROACH 8: Separate models per time point ===\n")
approach8 <- tryCatch({
  # Reshape to have all time points as separate variables
  reshaped <- test_data %>%
    mutate(time_cat = paste0("t", time)) %>%
    pivot_wider(
      id_cols = patient_id,
      names_from = time_cat,
      values_from = hospital_visits
    )
  
  # Just use first few time points as predictors
  formula_str <- paste("cbind(", paste0("t", 0:19, collapse = ","), ") ~ 1")
  
  flexmix(
    as.formula(formula_str),
    data = reshaped,
    k = 4,
    model = FLXMRglm(family = "poisson"),
    control = list(minprior = 0.05, iter.max = 100, verbose = 0)
  )
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
  NULL
})

if (!is.null(approach8)) {
  post_rows <- nrow(posterior(approach8))
  is_correct <- post_rows == 100
  
  if (is_correct) {
    cat("✓ SUCCESS - CORRECT PATIENT-LEVEL CLUSTERING\n")
  } else {
    cat("✗ FAILED - WRONG GRANULARITY\n")
  }
  cat("  Posterior rows:", post_rows, "(expected: 100)\n")
  cat("  Clustering at:", ifelse(is_correct, "PATIENT level ✓", "OBSERVATION level ✗"), "\n\n")
} else {
  cat("✗ FAILED - Model did not converge\n\n")
}

approach8_valid <- !is.null(approach8) && nrow(posterior(approach8)) == 100

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n\n=== SUMMARY OF ALL APPROACHES ===\n\n")

results <- data.frame(
  Approach = 1:8,
  Method = c(
    "Long + | operator",
    "Long + factor(id)",
    "Long + . ~ . syntax",
    "Wide + matrix",
    "Long + FLXMRglmfix",
    "Pre-aggregate features",
    "stepFlexmix wrapper",
    "Reshape multivariate"
  ),
  Converged = c(
    !is.null(approach1),
    !is.null(approach2),
    !is.null(approach3),
    !is.null(approach4),
    !is.null(approach5),
    !is.null(approach6),
    !is.null(approach7),
    !is.null(approach8)
  ),
  Patient_Level = c(
    approach1_valid,
    approach2_valid,
    approach3_valid,
    approach4_valid,
    approach5_valid,
    approach6_valid,
    approach7_valid,
    approach8_valid
  ),
  Likelihood = c(85, 75, 70, 60, 50, 40, 65, 30)
)

print(results)

cat("\n")
if (any(results$Patient_Level)) {
  valid_approaches <- which(results$Patient_Level)
  cat("✓✓✓ CORRECT APPROACHES (patient-level clustering):", 
      paste(valid_approaches, collapse = ", "), "\n\n")
  
  # Identify the best working approach
  best <- valid_approaches[1]
  cat("RECOMMENDED: Use Approach", best, "-", results$Method[best], "\n\n")
  
  # Show how to access the working model
  cat("To use the working model:\n")
  cat("  model <- approach", best, "\n", sep = "")
  cat("  posterior_probs <- posterior(model)  # 100 x 4 matrix\n")
  cat("  cluster_assignments <- clusters(model)  # 100-length vector\n\n")
  
} else if (any(results$Converged)) {
  cat("⚠ Some models converged but are clustering at OBSERVATION level (not patient level)\n")
  cat("  This means they're treating each row as independent, not grouping by patient\n\n")
  cat("RECOMMENDATION: Use the latrend package wrapper instead\n")
} else {
  cat("✗ None of the approaches worked!\n")
  cat("\nPossible issues:\n")
  cat("1. flexmix version incompatibility\n")
  cat("2. Data format issues\n")
  cat("3. Missing dependencies\n")
  cat("\nRECOMMENDATION: Use the latrend package wrapper instead\n")
}

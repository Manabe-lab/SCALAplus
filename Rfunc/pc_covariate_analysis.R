# PC Covariate Analysis Functions
# This script provides functions to analyze how principal components (PCs)
# relate to various covariates (biological/technical factors)

#' Analyze PC Covariates
#'
#' Analyzes how each PC is explained by various covariates using linear models
#'
#' @param obj Seurat object
#' @param reduction_name Name of the reduction to use (e.g., "RNA.pca", "ATAC.lsi")
#' @param fixed_covariates Character vector of covariate names from meta.data
#' @param random_effect Character string or NULL for random effect (e.g., "donor")
#' @param pcs_to_use Character vector of PC names or NULL (defaults to first 20)
#' @param include_interactions Logical, whether to include 2-way interactions between covariates
#'
#' @return List containing per_pc_stats, model_details, plot_data
analyze_pc_covariates <- function(
    obj,
    reduction_name = "RNA.pca",
    fixed_covariates,
    random_effect = NULL,
    pcs_to_use = NULL,
    include_interactions = FALSE
) {

  # Load required libraries
  library(dplyr)
  library(tidyr)
  library(lme4)
  library(lmerTest)
  library(MuMIn)
  library(broom)

  # Validate inputs
  if (!reduction_name %in% names(obj@reductions)) {
    stop(paste("Reduction", reduction_name, "not found in Seurat object"))
  }

  # Get PC embeddings and key
  reduction_obj <- obj@reductions[[reduction_name]]
  pc_embeddings <- reduction_obj@cell.embeddings
  reduction_key <- reduction_obj@key

  # Get original column names
  original_colnames <- colnames(pc_embeddings)

  # Default to first 20 PCs if not specified
  if (is.null(pcs_to_use)) {
    n_pcs <- min(20, ncol(pc_embeddings))
    # Use the reduction key to construct PC names
    pcs_to_use <- paste0(reduction_key, 1:n_pcs)
  }

  # Validate PC names
  available_pcs <- colnames(pc_embeddings)
  pcs_to_use <- intersect(pcs_to_use, available_pcs)

  if (length(pcs_to_use) == 0) {
    stop("No valid PCs found. Available PCs: ", paste(head(available_pcs), collapse=", "))
  }

  # Get metadata
  metadata <- obj@meta.data

  # Validate covariates exist in metadata
  missing_covariates <- setdiff(fixed_covariates, colnames(metadata))
  if (length(missing_covariates) > 0) {
    stop("Covariates not found in metadata: ", paste(missing_covariates, collapse=", "))
  }

  # Prepare data frame
  analysis_data <- cbind(pc_embeddings[, pcs_to_use, drop=FALSE], metadata)

  # Convert covariates to appropriate types
  covariate_info <- list()
  for (cov in fixed_covariates) {
    if (is.character(analysis_data[[cov]]) || is.factor(analysis_data[[cov]])) {
      analysis_data[[cov]] <- as.factor(analysis_data[[cov]])
      covariate_info[[cov]] <- list(
        type = "categorical",
        baseline = levels(analysis_data[[cov]])[1],
        n_levels = length(levels(analysis_data[[cov]]))
      )
    } else {
      analysis_data[[cov]] <- as.numeric(analysis_data[[cov]])
      covariate_info[[cov]] <- list(
        type = "continuous",
        baseline = NA,
        n_levels = NA
      )
    }
  }

  # Generate interaction terms if requested
  # Only Covariate 1 × Covariate 2 interaction
  interaction_terms <- NULL
  all_terms <- fixed_covariates

  if (include_interactions && length(fixed_covariates) >= 2) {
    interaction_terms <- paste(fixed_covariates[1], fixed_covariates[2], sep = ":")
    all_terms <- c(fixed_covariates, interaction_terms)
    cat("Including interaction term:", interaction_terms, "\n")
  }

  # Initialize results storage
  per_pc_stats <- list()
  model_details <- list()
  plot_data_list <- list()

  # Analyze each PC
  for (pc in pcs_to_use) {

    cat("Analyzing", pc, "...\n")

    # Prepare formula (with interactions if requested)
    if (include_interactions && !is.null(interaction_terms)) {
      formula_str <- paste(pc, "~", paste(fixed_covariates, collapse = " + "), "+",
                          paste(interaction_terms, collapse = " + "))
    } else {
      formula_str <- paste(pc, "~", paste(fixed_covariates, collapse = " + "))
    }

    # Create complete cases subset
    vars_needed <- c(pc, fixed_covariates)
    if (!is.null(random_effect)) {
      vars_needed <- c(vars_needed, random_effect)
    }

    complete_idx <- complete.cases(analysis_data[, vars_needed])
    pc_data <- analysis_data[complete_idx, ]
    n_cells <- nrow(pc_data)

    if (n_cells < 10) {
      warning(paste("Too few cells for", pc, "- skipping"))
      next
    }

    # Initialize results for this PC
    pc_results <- data.frame(
      pc = pc,
      n_cells_used = n_cells
    )

    # Fit fixed effects model
    tryCatch({
      lm_model <- lm(as.formula(formula_str), data = pc_data)
      lm_summary <- summary(lm_model)

      # Store model
      model_details[[pc]]$lm_summary <- lm_summary
      model_details[[pc]]$lm_model <- lm_model

      # Get R-squared
      pc_results$fixed_r2 <- lm_summary$r.squared
      pc_results$fixed_adj_r2 <- lm_summary$adj.r.squared

      # Extract coefficients for each covariate
      coef_df <- as.data.frame(lm_summary$coefficients)
      coef_df$term <- rownames(coef_df)

      # Calculate partial R-squared for each covariate and interaction term
      # Also store reduced model information
      model_details[[pc]]$reduced_models <- list()
      model_details[[pc]]$model_comparison <- list()
      model_details[[pc]]$anova_comparisons <- list()

      for (term in all_terms) {

        # Check if this is an interaction term
        is_interaction <- grepl(":", term)

        # Extract coefficients related to this term
        if (is_interaction) {
          # For interactions, look for exact match (e.g., "A:B")
          term_pattern <- paste0("^", gsub(":", ".*:", term))
          term_in_coef <- grep(term_pattern, coef_df$term, value = TRUE)
        } else {
          # For main effects, look for terms starting with covariate name
          term_in_coef <- grep(paste0("^", term), coef_df$term, value = TRUE)
        }

        if (length(term_in_coef) > 0) {
          # Get primary coefficient and p-value
          primary_coef <- term_in_coef[1]
          pc_results[[paste0("fixed_coef_", term)]] <- coef_df[primary_coef, "Estimate"]
          pc_results[[paste0("fixed_pval_", term)]] <- coef_df[primary_coef, "Pr(>|t|)"]

          # Calculate partial R-squared and store reduced model
          # For main effects: remove that covariate (and its interactions if present)
          # For interactions: remove only that interaction term
          if (is_interaction) {
            # Remove only this interaction term
            formula_reduced <- paste(pc, "~",
                                    paste(setdiff(all_terms, term), collapse = " + "))
          } else {
            # Remove main effect and all interactions involving this covariate
            terms_to_remove <- c(term, grep(paste0("(^|:)", term, "($|:)"), all_terms, value = TRUE))
            terms_to_keep <- setdiff(all_terms, terms_to_remove)
            if (length(terms_to_keep) > 0) {
              formula_reduced <- paste(pc, "~", paste(terms_to_keep, collapse = " + "))
            } else {
              formula_reduced <- paste(pc, "~ 1")  # Intercept-only model
            }
          }

          lm_reduced <- lm(as.formula(formula_reduced), data = pc_data)
          lm_reduced_summary <- summary(lm_reduced)

          partial_r2 <- max(0, lm_summary$r.squared - lm_reduced_summary$r.squared)
          pc_results[[paste0("partial_r2_", term)]] <- partial_r2

          # Store reduced model information
          model_details[[pc]]$reduced_models[[term]] <- list(
            model = lm_reduced,
            summary = lm_reduced_summary,
            formula = formula_reduced
          )

          # Perform ANOVA F-test comparing reduced vs full model
          anova_test <- anova(lm_reduced, lm_model)
          f_statistic <- anova_test$F[2]
          f_pvalue <- anova_test$`Pr(>F)`[2]

          # Store global p-value (for the entire factor, not just one coefficient)
          pc_results[[paste0("fixed_global_pval_", term)]] <- f_pvalue
          pc_results[[paste0("fixed_delta_aic_", term)]] <- AIC(lm_reduced) - AIC(lm_model)

          # Store model comparison
          model_details[[pc]]$model_comparison[[term]] <- data.frame(
            term_removed = term,
            term_type = ifelse(is_interaction, "interaction", "main_effect"),
            full_model_r2 = lm_summary$r.squared,
            full_model_adj_r2 = lm_summary$adj.r.squared,
            full_model_aic = AIC(lm_model),
            reduced_model_r2 = lm_reduced_summary$r.squared,
            reduced_model_adj_r2 = lm_reduced_summary$adj.r.squared,
            reduced_model_aic = AIC(lm_reduced),
            partial_r2 = partial_r2,
            delta_aic = AIC(lm_reduced) - AIC(lm_model),
            f_statistic = f_statistic,
            f_test_pvalue = f_pvalue
          )

          # Store ANOVA table for this comparison
          model_details[[pc]]$anova_comparisons[[term]] <- anova_test

          # Store for plotting (only for main effects, not interactions)
          if (!is_interaction) {
            plot_data_list[[length(plot_data_list) + 1]] <- data.frame(
              pc = pc,
              covariate = term,
              model_type = "fixed",
              effect_size = coef_df[primary_coef, "Estimate"],
              p_value = coef_df[primary_coef, "Pr(>|t|)"],  # Individual coefficient p-value
              global_p_value = f_pvalue,  # Global p-value for entire factor
              partial_r2 = partial_r2,
              covariate_type = covariate_info[[term]]$type
            )
          }
        } else {
          pc_results[[paste0("fixed_coef_", term)]] <- NA
          pc_results[[paste0("fixed_pval_", term)]] <- NA
          pc_results[[paste0("partial_r2_", term)]] <- NA
        }
      }

      # Store ANOVA table
      model_details[[pc]]$anova_table <- anova(lm_model)

    }, error = function(e) {
      warning(paste("Error fitting fixed model for", pc, ":", e$message))
      pc_results$fixed_r2 <- NA
      pc_results$fixed_adj_r2 <- NA
    })

    # Fit mixed effects model if random effect specified
    if (!is.null(random_effect)) {

      tryCatch({
        # Build random effects formula
        if (length(random_effect) == 1) {
          random_formula <- paste("+ (1 |", random_effect, ")")
        } else {
          random_parts <- sapply(random_effect, function(re) paste("(1 |", re, ")"))
          random_formula <- paste("+", paste(random_parts, collapse = " + "))
        }
        formula_mixed <- paste(formula_str, random_formula)
        lmer_model <- lmer(as.formula(formula_mixed), data = pc_data)
        lmer_summary <- summary(lmer_model)

        # Store model
        model_details[[pc]]$lmer_summary <- lmer_summary
        model_details[[pc]]$lmer_model <- lmer_model

        # Check convergence
        pc_results$model_mixed_converged <- TRUE

        # Get R-squared values
        r2_values <- r.squaredGLMM(lmer_model)
        pc_results$mixed_r2_marginal <- r2_values[1, "R2m"]
        pc_results$mixed_r2_conditional <- r2_values[1, "R2c"]

        # Extract coefficients
        coef_df_mixed <- as.data.frame(lmer_summary$coefficients)
        coef_df_mixed$term <- rownames(coef_df_mixed)

        # Initialize storage for mixed model comparisons
        model_details[[pc]]$lmer_reduced_models <- list()
        model_details[[pc]]$lmer_model_comparison <- list()
        model_details[[pc]]$lrt_comparisons <- list()

        for (term in all_terms) {
          # Check if this is an interaction term
          is_interaction <- grepl(":", term)

          # Extract coefficients related to this term
          if (is_interaction) {
            term_pattern <- paste0("^", gsub(":", ".*:", term))
            term_in_coef <- grep(term_pattern, coef_df_mixed$term, value = TRUE)
          } else {
            term_in_coef <- grep(paste0("^", term), coef_df_mixed$term, value = TRUE)
          }

          if (length(term_in_coef) > 0) {
            primary_coef <- term_in_coef[1]
            pc_results[[paste0("mixed_coef_", term)]] <- coef_df_mixed[primary_coef, "Estimate"]
            pc_results[[paste0("mixed_pval_", term)]] <- coef_df_mixed[primary_coef, "Pr(>|t|)"]

            # Fit reduced mixed model (without this term)
            if (is_interaction) {
              # Remove only this interaction term
              terms_to_keep <- setdiff(all_terms, term)
            } else {
              # Remove main effect and all interactions involving this covariate
              terms_to_remove <- c(term, grep(paste0("(^|:)", term, "($|:)"), all_terms, value = TRUE))
              terms_to_keep <- setdiff(all_terms, terms_to_remove)
            }

            if (length(terms_to_keep) > 0) {
              formula_mixed_reduced <- paste(pc, "~",
                                            paste(terms_to_keep, collapse = " + "),
                                            random_formula)
            } else {
              formula_mixed_reduced <- paste(pc, "~ 1", random_formula)
            }
            lmer_reduced <- lmer(as.formula(formula_mixed_reduced), data = pc_data)

            # Perform likelihood ratio test (LRT)
            lrt_test <- anova(lmer_reduced, lmer_model)
            chisq_statistic <- lrt_test$Chisq[2]
            lrt_pvalue <- lrt_test$`Pr(>Chisq)`[2]

            # Store global p-value from LRT (for the entire factor)
            pc_results[[paste0("mixed_global_pval_", term)]] <- lrt_pvalue
            pc_results[[paste0("mixed_delta_aic_", term)]] <- AIC(lmer_reduced) - AIC(lmer_model)

            # Store reduced model
            model_details[[pc]]$lmer_reduced_models[[term]] <- list(
              model = lmer_reduced,
              summary = summary(lmer_reduced),
              formula = formula_mixed_reduced
            )

            # Store LRT comparison
            model_details[[pc]]$lrt_comparisons[[term]] <- lrt_test

            # Store comparison summary
            r2_reduced <- r.squaredGLMM(lmer_reduced)
            model_details[[pc]]$lmer_model_comparison[[term]] <- data.frame(
              term_removed = term,
              term_type = ifelse(is_interaction, "interaction", "main_effect"),
              full_model_r2m = r2_values[1, "R2m"],
              full_model_r2c = r2_values[1, "R2c"],
              full_model_aic = AIC(lmer_model),
              reduced_model_r2m = r2_reduced[1, "R2m"],
              reduced_model_r2c = r2_reduced[1, "R2c"],
              reduced_model_aic = AIC(lmer_reduced),
              delta_aic = AIC(lmer_reduced) - AIC(lmer_model),
              chisq_statistic = chisq_statistic,
              lrt_pvalue = lrt_pvalue
            )

            # Add to plot data (only for main effects, not interactions)
            if (!is_interaction) {
              plot_data_list[[length(plot_data_list) + 1]] <- data.frame(
                pc = pc,
                covariate = term,
                model_type = "mixed",
                effect_size = coef_df_mixed[primary_coef, "Estimate"],
                p_value = coef_df_mixed[primary_coef, "Pr(>|t|)"],  # Individual coefficient p-value
                global_p_value = lrt_pvalue,  # Global p-value from LRT
                partial_r2 = NA,
                covariate_type = covariate_info[[term]]$type
              )
            }
          } else {
            pc_results[[paste0("mixed_coef_", term)]] <- NA
            pc_results[[paste0("mixed_pval_", term)]] <- NA
          }
        }

      }, error = function(e) {
        warning(paste("Error fitting mixed model for", pc, ":", e$message))
        pc_results$model_mixed_converged <- FALSE
        pc_results$mixed_r2_marginal <- NA
        pc_results$mixed_r2_conditional <- NA
      })

    } else {
      pc_results$model_mixed_converged <- NA
      pc_results$mixed_r2_marginal <- NA
      pc_results$mixed_r2_conditional <- NA
    }

    # Add baseline information
    for (cov in fixed_covariates) {
      pc_results[[paste0("baseline_", cov)]] <- as.character(covariate_info[[cov]]$baseline)
    }

    per_pc_stats[[pc]] <- pc_results
  }

  # Combine results
  per_pc_stats_df <- bind_rows(per_pc_stats)
  plot_data_df <- bind_rows(plot_data_list)

  # Return results
  return(list(
    per_pc_stats = per_pc_stats_df,
    model_details = model_details,
    plot_data = plot_data_df,
    covariate_info = covariate_info
  ))
}


#' Plot PC vs Covariate
#'
#' Creates a visualization showing how a specific PC relates to a covariate
#'
#' @param obj Seurat object
#' @param reduction_name Name of the reduction to use
#' @param pc PC name (e.g., "PC_4")
#' @param covariate Covariate name from meta.data
#' @param analysis_results Optional results from analyze_pc_covariates to add stats
#'
#' @return ggplot object
plot_pc_vs_covariate <- function(
    obj,
    reduction_name = "RNA.pca",
    pc,
    covariate,
    analysis_results = NULL
) {

  # Load required libraries
  library(ggplot2)
  library(dplyr)

  # Get PC embeddings (keep original column names)
  pc_embeddings <- obj@reductions[[reduction_name]]@cell.embeddings

  # Validate PC
  if (!pc %in% colnames(pc_embeddings)) {
    stop(paste("PC", pc, "not found in reduction", reduction_name))
  }

  # Get metadata
  metadata <- obj@meta.data

  # Validate covariate
  if (!covariate %in% colnames(metadata)) {
    stop(paste("Covariate", covariate, "not found in metadata"))
  }

  # Prepare plot data
  plot_df <- data.frame(
    pc_score = pc_embeddings[, pc],
    covariate_value = metadata[[covariate]]
  )

  # Remove NAs
  plot_df <- plot_df[complete.cases(plot_df), ]

  # Check if categorical or continuous
  is_categorical <- is.character(plot_df$covariate_value) || is.factor(plot_df$covariate_value)

  # Create base plot
  if (is_categorical) {
    plot_df$covariate_value <- as.factor(plot_df$covariate_value)

    p <- ggplot(plot_df, aes(x = covariate_value, y = pc_score, fill = covariate_value)) +
      geom_boxplot(outlier.shape = NA, alpha = 0.7) +
      geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
      labs(
        x = covariate,
        y = paste(pc, "score"),
        title = paste(pc, "vs", covariate)
      ) +
      theme_classic() +
      theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1)
      )

  } else {
    plot_df$covariate_value <- as.numeric(plot_df$covariate_value)

    p <- ggplot(plot_df, aes(x = covariate_value, y = pc_score)) +
      geom_point(alpha = 0.3, size = 0.5) +
      geom_smooth(method = "lm", se = TRUE, color = "blue") +
      labs(
        x = covariate,
        y = paste(pc, "score"),
        title = paste(pc, "vs", covariate)
      ) +
      theme_classic()
  }

  # Add statistics if available
  if (!is.null(analysis_results)) {
    pc_stats <- analysis_results$per_pc_stats %>%
      dplyr::filter(pc == !!pc)

    if (nrow(pc_stats) > 0) {
      coef_col <- paste0("fixed_coef_", covariate)
      global_pval_col <- paste0("fixed_global_pval_", covariate)
      partial_r2_col <- paste0("partial_r2_", covariate)

      # For categorical variables: show global p-value and partial R² only
      # For continuous variables: show β, p-value, and partial R²
      if (is_categorical) {
        # Categorical: use global p-value from F-test/LRT
        if (all(c(global_pval_col, partial_r2_col) %in% colnames(pc_stats))) {
          global_pval <- pc_stats[[global_pval_col]]
          partial_r2 <- pc_stats[[partial_r2_col]]

          if (!is.na(global_pval) && !is.na(partial_r2)) {
            stat_text <- sprintf(
              "Global p = %.2e\nPartial R² = %.3f",
              global_pval, partial_r2
            )

            p <- p +
              annotate(
                "text",
                x = Inf,
                y = Inf,
                label = stat_text,
                hjust = 1.1,
                vjust = 1.1,
                size = 3,
                color = "black"
              )
          }
        }
      } else {
        # Continuous: use coefficient and individual p-value
        pval_col <- paste0("fixed_pval_", covariate)
        if (all(c(coef_col, pval_col, partial_r2_col) %in% colnames(pc_stats))) {
          coef <- pc_stats[[coef_col]]
          pval <- pc_stats[[pval_col]]
          partial_r2 <- pc_stats[[partial_r2_col]]

          if (!is.na(coef) && !is.na(pval) && !is.na(partial_r2)) {
            stat_text <- sprintf(
              "β = %.3f, p = %.2e\nPartial R² = %.3f",
              coef, pval, partial_r2
            )

            p <- p +
              annotate(
                "text",
                x = Inf,
                y = Inf,
                label = stat_text,
                hjust = 1.1,
                vjust = 1.1,
                size = 3,
                color = "black"
              )
          }
        }
      }
    }
  }

  return(p)
}


#' Create Summary Heatmap
#'
#' Creates a heatmap showing partial R² values for all PC-covariate combinations
#'
#' @param analysis_results Results from analyze_pc_covariates
#'
#' @return ggplot object
plot_partial_r2_heatmap <- function(analysis_results) {

  # Load required libraries
  library(ggplot2)
  library(dplyr)
  library(tidyr)

  # Extract partial R² values
  stats_df <- analysis_results$per_pc_stats

  # Get covariate columns
  partial_r2_cols <- grep("^partial_r2_", colnames(stats_df), value = TRUE)

  if (length(partial_r2_cols) == 0) {
    stop("No partial R² values found in results")
  }

  # Reshape to long format
  plot_data <- stats_df %>%
    dplyr::select(pc, all_of(partial_r2_cols)) %>%
    tidyr::pivot_longer(
      cols = -pc,
      names_to = "covariate",
      values_to = "partial_r2"
    ) %>%
    dplyr::mutate(
      covariate = gsub("^partial_r2_", "", covariate)
    )

  # Create heatmap
  p <- ggplot(plot_data, aes(x = covariate, y = pc, fill = partial_r2)) +
    geom_tile(color = "white") +
    scale_fill_gradient2(
      low = "white",
      mid = "yellow",
      high = "red",
      midpoint = 0.1,
      limits = c(0, NA),
      na.value = "grey80",
      name = "Partial R²"
    ) +
    geom_text(aes(label = sprintf("%.2f", partial_r2)), size = 3) +
    labs(
      title = "PC Covariate Associations",
      x = "Covariate",
      y = "Principal Component"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid = element_blank()
    )

  return(p)
}


#' Create P-value Heatmap
#'
#' Creates a heatmap showing -log10(p-values) for all PC-covariate combinations
#'
#' @param analysis_results Results from analyze_pc_covariates
#'
#' @return ggplot object
plot_pvalue_heatmap <- function(analysis_results) {

  # Load required libraries
  library(ggplot2)
  library(dplyr)
  library(tidyr)

  # Extract p-values
  stats_df <- analysis_results$per_pc_stats

  # Get global p-value columns (use global p-values for proper factor-level significance)
  global_pval_cols <- grep("^fixed_global_pval_", colnames(stats_df), value = TRUE)

  if (length(global_pval_cols) == 0) {
    stop("No global p-values found in results")
  }

  # Reshape to long format
  plot_data <- stats_df %>%
    dplyr::select(pc, all_of(global_pval_cols)) %>%
    tidyr::pivot_longer(
      cols = -pc,
      names_to = "covariate",
      values_to = "p_value"
    ) %>%
    dplyr::mutate(
      covariate = gsub("^fixed_global_pval_", "", covariate),
      neg_log10_p = -log10(p_value + 1e-300)  # Add small value to avoid -Inf
    )

  # Create heatmap
  p <- ggplot(plot_data, aes(x = covariate, y = pc, fill = neg_log10_p)) +
    geom_tile(color = "white") +
    scale_fill_gradient2(
      low = "white",
      mid = "orange",
      high = "darkred",
      midpoint = 5,
      limits = c(0, NA),
      na.value = "grey80",
      name = "-log10(p)"
    ) +
    geom_text(
      aes(label = ifelse(p_value < 0.05, "*", "")),
      size = 6,
      color = "black"
    ) +
    labs(
      title = "PC Covariate Association Significance",
      subtitle = "* indicates p < 0.05",
      x = "Covariate",
      y = "Principal Component"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid = element_blank()
    )

  return(p)
}


# Example usage (commented out)
# res <- analyze_pc_covariates(
#   obj = my_seurat,
#   reduction_name = "RNA.pca",
#   fixed_covariates = c("subtype", "sex", "batch", "age"),
#   random_effect = "donor",
#   pcs_to_use = paste0("PC_", 1:10)
# )
#
# head(res$per_pc_stats)
#
# p <- plot_pc_vs_covariate(
#   obj = my_seurat,
#   reduction_name = "RNA.pca",
#   pc = "PC_4",
#   covariate = "sex",
#   analysis_results = res
# )
# print(p)
#
# heatmap_p <- plot_partial_r2_heatmap(res)
# print(heatmap_p)
#
# pval_heatmap <- plot_pvalue_heatmap(res)
# print(pval_heatmap)

# Quick Reference Guide: GBTM Model Switching

## Overview
This guide explains how to use the `gbtm_flexible.Rmd` file to easily switch between different distribution types for Group-Based Trajectory Modeling.

## Supported Models

| Model | Code | When to Use | Key Features |
|-------|------|-------------|--------------|
| **Poisson** | `"poisson"` | Variance ≈ Mean, no structural zeros | Simplest, fastest |
| **Negative Binomial (NB)** | `"nb"` | Variance > Mean (overdispersion) | **RECOMMENDED for most healthcare data** |
| **Zero-Inflated Poisson (ZIP)** | `"zip"` | Structural zeros, Variance ≈ Mean | Handles two types of zeros |
| **Zero-Inflated NB (ZINB)** | `"zinb"` | Structural zeros + overdispersion | Most complex, use custom implementation |

## How to Switch Models

### Step 1: Open the File
Open `gbtm_flexible.Rmd` in RStudio

### Step 2: Find the Configuration Section
Look for this code block (around line 120):

```r
# ========================================
# CONFIGURATION: Change model type here
# ========================================
# Options: "poisson", "nb", "zip", "zinb"
model_type <- "nb"  # <--- CHANGE THIS TO SWITCH MODELS
# ========================================
```

### Step 3: Change the Model Type
Simply change `"nb"` to one of:
- `"poisson"` for Poisson GBTM
- `"nb"` for Negative Binomial GBTM ← **START HERE**
- `"zip"` for Zero-Inflated Poisson GBTM
- `"zinb"` for ZINB (requires custom implementation)

### Step 4: Re-run the Notebook
- Click "Run All" or
- Knit the document to HTML

## Decision Tree

```
START: I have hospital visit count data

└─ Question 1: Is variance > mean within trajectory classes?
   │
   ├─ YES (dispersion ratio > 1.5)
   │  └─ Question 2: Are there structural zeros?
   │     ├─ YES (>5% patients with all zeros) → Use ZINB
   │     └─ NO → Use NB ← **MOST LIKELY FOR YOU**
   │
   └─ NO (dispersion ratio ≈ 1.0)
      └─ Question 2: Are there structural zeros?
         ├─ YES → Use ZIP
         └─ NO → Use Poisson
```

## For Your Specific Case

Based on your description:
1. **Zeros = healthy quarters** (not structural)
2. **Zeros cluster by group** (low-utilization class has more zeros)
3. **Healthcare data** (likely overdispersion)

**Recommendation: Start with `model_type <- "nb"`**

## What Gets Automated

When you switch models, the code automatically:
- ✅ Uses the appropriate `flexmix` driver
- ✅ Fits 1-class and 4-class models
- ✅ Extracts posterior probabilities
- ✅ Creates trajectory plots
- ✅ Calculates BIC/AIC for comparison
- ✅ Checks within-class overdispersion
- ✅ Characterizes classes by demographics

## Key Outputs

After running, you'll get:

1. **Model Comparison Table** - Shows BIC/AIC for 1-class vs 4-class
2. **Dispersion Diagnostics** - Tells you if NB is needed
3. **Trajectory Plots** - Visual representation of the 4 classes
4. **Class Assignments** - Each patient assigned to a class with posterior probability
5. **Demographic Tables** - Characteristics of each trajectory class

## Comparing Models

To compare Poisson vs NB vs ZIP:

1. Run with `model_type <- "poisson"`, note the BIC
2. Run with `model_type <- "nb"`, note the BIC
3. Run with `model_type <- "zip"`, note the BIC
4. **Choose the model with LOWEST BIC**

Typical result: NB will have lowest BIC for healthcare data

## Advanced: ZINB Implementation

For ZINB (not supported directly by flexmix):

1. Scroll to the "Custom ZINB Implementation" section
2. Set the chunk option `eval=TRUE`
3. Run on a **small subset first** (1000 patients) to test
4. If it works, run on full dataset (will take 12+ hours)

**Note:** ZINB is complex and computationally intensive. Only use if:
- You have confirmed structural zeros (patients with ALL quarters = 0)
- AND you have overdispersion
- AND regular NB-GBTM doesn't fit well

## Troubleshooting

### "Package 'countreg' not found"
```r
install.packages("countreg", repos="http://R-Forge.R-project.org")
```

### "Model failed to converge"
- Try increasing `iter.max` in the control parameters
- Try different starting values (change seed)
- Reduce number of classes (k)

### "Memory error"
- Work with a subset of data first
- Reduce number of classes
- Use simpler model (Poisson instead of NB)

## Performance Expectations

On 10,000 patients × 20 quarters:
- **Poisson**: ~5 minutes
- **NB**: ~15 minutes ← **YOUR TEST CASE**
- **ZIP**: ~10 minutes
- **ZINB (custom)**: ~60 minutes

On 400,000 patients × 20 quarters:
- **Poisson**: ~3 hours
- **NB**: ~8-12 hours ← **YOUR FULL RUN**
- **ZIP**: ~6 hours
- **ZINB (custom)**: ~24+ hours

## Validation

The code includes a validation section (lines 370-395) that:
- Creates confusion matrix vs. true classes
- Calculates overall accuracy
- Calculates class-specific accuracy
- Computes Adjusted Rand Index

This only works if you have a `trajectory_group` variable from data generation.

## Contact Points for Consortium

When presenting to consortium, emphasize:

1. **Model Selection was Data-Driven**
   - Show the dispersion diagnostics
   - Show BIC comparison table
   - Explain why NB was chosen over Poisson

2. **GBTM Framework Preserved**
   - Using established `flexmix` package
   - Following Nagin methodology
   - Comparable to SAS PROC TRAJ

3. **Transparency**
   - All code available in reproducible R Markdown
   - Can easily switch models for sensitivity analysis
   - Diagnostic checks built-in

## Summary

**TL;DR:**
1. Open `gbtm_flexible.Rmd`
2. Change line ~120: `model_type <- "nb"`
3. Run the notebook
4. Look at BIC, trajectories, and class characteristics
5. If needed, switch to another model and compare

**Most likely outcome:** NB-GBTM will be your final choice.

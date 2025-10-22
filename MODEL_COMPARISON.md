# Complete Model Comparison: Poisson vs ZIP vs NB vs ZINB GBTM

## Executive Summary

For hospital visit trajectory data with:
- 19% zeros (from healthy quarters, not structural barriers)
- Patients completed TB treatment (all can access healthcare)
- Korean Medicare system (universal coverage)
- 20 quarters per patient

**Recommendation: Negative Binomial (NB) GBTM**

---

## Detailed Model Comparison

### 1. Poisson GBTM

**Mathematical Structure:**
```
Class j: Y_it ~ Poisson(λ_jt)
Where: λ_jt = exp(β_j0 + β_j1*t + β_j2*t²)
Constraint: E[Y] = Var[Y] = λ
```

**Assumptions:**
- ✅ Zeros occur naturally from Poisson process
- ❌ Variance equals mean (rarely true in real data)
- ✅ All patients can have visits (no structural zeros)

**When Zero Rate is High (19%):**
- Achieves high zero rate by having low mean (λ < 1)
- Example: λ = 0.5 → 60.7% zeros
- Problem: Forces variance = 0.5 (unrealistic)

**Pros:**
- Fastest computation
- Simplest interpretation
- Fewest parameters
- Standard baseline for comparison

**Cons:**
- **Underestimates variance** → Standard errors too small
- **Overconfident predictions** → CI too narrow
- **Poor fit for heterogeneous data**
- Rarely appropriate for real healthcare data

**Use Case:** Almost never for healthcare utilization data

---

### 2. Zero-Inflated Poisson (ZIP) GBTM

**Mathematical Structure:**
```
Class j: 
  P(Y = 0) = π_j + (1-π_j) × e^(-λ_j)
  P(Y = k) = (1-π_j) × Poisson(λ_j) for k > 0
  
Where: π_j = proportion of "structural zeros" in class j
```

**Assumptions:**
- ✅ TWO types of zeros:
  - Type 1: Structural zeros (proportion π) - patients who CAN'T/WON'T visit
  - Type 2: Poisson zeros - patients who CAN visit but happened to have zero
- ❌ Variance = mean for non-zero component
- ❌ Clear distinction between structural vs. random zeros

**When Zero Rate is High (19%):**
- Can achieve 19% zeros by:
  - Option A: π = 0.10, λ = 0.5 → some structural + some Poisson zeros
  - Option B: π = 0, λ = 0.2 → all Poisson zeros (reduces to Poisson)
- Problem: Still forces variance = mean for non-zeros

**Pros:**
- Explicitly models excess zeros
- Can distinguish "never users" from "occasional users"
- Flexible zero rate (π parameter)

**Cons:**
- **Misrepresents data-generating process** (your zeros aren't structural)
- **Still can't handle overdispersion** in non-zeros
- More parameters than Poisson (slower, complex)
- Interpretation: "π% are structural zeros" doesn't match your context

**Use Case:** Data with mix of people who CAN'T access care + people who CAN access care
- Example: Study with uninsured AND insured patients
- **NOT your case** (all have Medicare, all completed treatment)

---

### 3. Negative Binomial (NB) GBTM ⭐ **RECOMMENDED**

**Mathematical Structure:**
```
Class j: Y_it ~ NegBin(μ_jt, θ_j)
Where: μ_jt = exp(β_j0 + β_j1*t + β_j2*t²)
       Var[Y] = μ + μ²/θ_j
       
θ_j = dispersion parameter (can differ by class)
```

**Assumptions:**
- ✅ Zeros occur naturally from low end of NegBin distribution
- ✅ Variance can be much greater than mean
- ✅ All patients are "potential users" (no structural zeros)
- ✅ Within-class heterogeneity in visit patterns

**When Zero Rate is High (19%):**
- Achieves high zeros naturally with low mean
- Example: μ = 0.5, θ = 1 → ~58% zeros, variance = 0.75
- Flexibility: Can adjust both mean AND variance independently

**Pros:**
- ✅ **Handles overdispersion** (variance > mean)
- ✅ **Theoretically appropriate** for your data (random zeros)
- ✅ **Robust**: Works well even if overdispersion is mild
- ✅ **Interpretable**: Single process generates all counts
- ✅ **Available in flexmix** (`FLXMRnegbin` driver)
- ✅ **Standard in healthcare research**

**Cons:**
- Slightly slower than Poisson (negligible)
- One extra parameter (θ) per class
- If overdispersion is absent, Poisson would be more parsimonious

**Use Case:** Count data with:
- Random zeros (from healthy/good periods)
- Within-group heterogeneity
- Variance > mean
- **← YOUR DATA**

---

### 4. Zero-Inflated Negative Binomial (ZINB) GBTM

**Mathematical Structure:**
```
Class j:
  P(Y = 0) = π_j + (1-π_j) × f_NB(0 | μ_j, θ_j)
  P(Y = k) = (1-π_j) × f_NB(k | μ_j, θ_j) for k > 0
  
Where: π_j = structural zero proportion
       f_NB = negative binomial probability mass function
```

**Assumptions:**
- ✅ TWO types of zeros (like ZIP)
- ✅ Overdispersion in non-zero counts (like NB)
- ❌ Requires structural zeros to be meaningful

**When Zero Rate is High (19%):**
- Maximum flexibility: π, μ, and θ all adjustable
- Example: π = 0.05, μ = 1.0, θ = 1.5
- Can fit almost any zero rate + variance combination

**Pros:**
- Most flexible model (handles everything)
- Appropriate IF structural zeros exist AND overdispersion present
- Can reduce to NB (if π = 0) or ZIP (if θ → ∞)

**Cons:**
- **Overkill for your data** (no structural zeros)
- Most complex: 3 parameters per class (π, μ, θ)
- Slowest computation (EM algorithm required)
- **Not directly available in flexmix** (need custom code)
- Hardest to interpret and defend
- Can overfit (too many parameters)

**Use Case:** Data with:
- Structural zeros (some people CAN'T access care)
- AND overdispersion (high variance in non-zeros)
- Example: Study with homeless + housed patients
- **NOT your case**

---

## Parameter Count Comparison

For 4-class model with quadratic time trends:

| Model | Parameters per Class | Total Parameters | Notes |
|-------|---------------------|------------------|-------|
| Poisson | 3 (β₀, β₁, β₂) | 12 + 3 = 15 | +3 for mixing proportions |
| ZIP | 4 (β₀, β₁, β₂, π) | 16 + 3 = 19 | π = zero-inflation rate |
| NB | 4 (β₀, β₁, β₂, θ) | 16 + 3 = 19 | θ = dispersion parameter |
| ZINB | 5 (β₀, β₁, β₂, π, θ) | 20 + 3 = 23 | Most complex |

**Implication:** NB and ZIP have same complexity, but NB is more appropriate for your data.

---

## Computational Time Comparison

Estimated runtime on 400,000 patients × 20 quarters (16GB RAM):

| Model | Test (10K patients) | Full (400K patients) | Scaling |
|-------|--------------------|--------------------|---------|
| Poisson | 5 min | ~3 hours | Linear |
| ZIP | 10 min | ~6 hours | Linear |
| NB | **15 min** | **~8-12 hours** | Linear |
| ZINB (custom) | 60 min | ~24+ hours | Depends on convergence |

**Recommendation:** Start with NB on 10K subset (15 min) to validate approach.

---

## How Each Model Handles Your 19% Zeros

### Scenario: "Low Utilizer" Class

**Your Data:**
- 19% overall zeros
- Low-utilizer class likely has ~50-60% zeros
- These are "healthy quarters" not "structural non-access"
- Within class: some patients have 0-1 visits, others have occasional spikes (0, 0, 5, 0)

**Poisson Approach:**
```
Mean = 0.8 visits/quarter
Predicted zeros: e^(-0.8) = 45%
Variance: 0.8 (forced)
PROBLEM: Actual variance likely ~2.5 (spikes cause high variance)
```

**ZIP Approach:**
```
π = 0.15 (15% structural zeros)
λ = 0.9 (among non-structural)
Predicted zeros: 15% + 85% × e^(-0.9) = 48%
Variance: Still forced to equal λ among non-structural zeros
PROBLEM: Misinterprets healthy quarters as "structural zeros"
```

**NB Approach:**
```
μ = 0.8
θ = 0.6 (allows overdispersion)
Predicted zeros: ~47% (from NegBin formula)
Variance: 0.8 + 0.8²/0.6 = 1.87
SUCCESS: Captures both zero rate AND variance appropriately
```

**ZINB Approach:**
```
π = 0.05 (minimal structural)
μ = 0.85
θ = 0.7
Predicted zeros: 5% + 95% × NegBin_zero_prob ≈ 49%
Variance: Similar to NB
PROBLEM: Extra complexity (π parameter) provides no benefit
```

---

## BIC Comparison (Expected)

Based on typical healthcare data, expected BIC differences:

| Model | Relative BIC | Interpretation |
|-------|-------------|----------------|
| Poisson | Baseline | Worst fit (ignores overdispersion) |
| ZIP | -50 to -100 | Slightly better, but still poor |
| **NB** | **-200 to -400** | **Best fit** (handles overdispersion) |
| ZINB | -150 to -350 | Similar to NB, but penalized for extra parameters |

**Conclusion:** NB typically wins on BIC for healthcare data without structural zeros.

---

## Interpretation Example

**Same trajectory, different models:**

### Poisson Interpretation:
> "Low-utilizer class has mean 0.8 visits/quarter. Zeros occur randomly from Poisson process."

**Problem:** Ignores that some patients consistently have 0, others have spikes.

### ZIP Interpretation:
> "Low-utilizer class: 15% are structural non-users (never visit), 85% follow Poisson with mean 0.9."

**Problem:** All patients CAN visit (have Medicare, completed treatment). No "structural non-users."

### NB Interpretation: ✅
> "Low-utilizer class has mean 0.8 visits/quarter with substantial patient heterogeneity (dispersion = 0.6). Some patients remain healthy with few visits, while others experience intermittent complications leading to occasional spikes. Zeros naturally occur during healthy periods."

**Success:** Accurately describes your data-generating process.

### ZINB Interpretation:
> "Low-utilizer class: 5% are structural non-users, 95% follow NegBin(μ=0.85, θ=0.7)."

**Problem:** Adds unnecessary "structural zero" concept when NB already fits well.

---

## Decision Matrix

| Your Data Has... | Use This Model | Reason |
|-----------------|---------------|---------|
| Random zeros + Variance ≈ Mean | Poisson | Simplest (unlikely) |
| Random zeros + Variance > Mean | **NB** ← YOU | Handles overdispersion |
| Structural zeros + Variance ≈ Mean | ZIP | Two zero types |
| Structural zeros + Variance > Mean | ZINB | Both features |

**Your situation:**
- ✅ Random zeros (healthy quarters)
- ✅ Variance > Mean (patient heterogeneity)
- ❌ No structural zeros (all have access)

**→ Use Negative Binomial (NB) GBTM**

---

## Validation Checklist

After fitting each model, check:

### ✅ Model Fit
- [ ] BIC lower than simpler models?
- [ ] Log-likelihood improved?
- [ ] Model converged?

### ✅ Residual Diagnostics
- [ ] Residuals show no patterns?
- [ ] Variance-mean relationship appropriate?
- [ ] No systematic over/under-prediction?

### ✅ Classification Quality
- [ ] Mean posterior probability > 0.7?
- [ ] Class sizes reasonable (5-40% each)?
- [ ] Trajectories interpretable?

### ✅ Clinical Face Validity
- [ ] Trajectory shapes make sense?
- [ ] Demographics differ between classes?
- [ ] Matches clinical knowledge?

**For your data:** NB should pass all checks, Poisson/ZIP will fail variance checks.

---

## Recommendation Summary

**Primary Recommendation: NB-GBTM**

**Rationale:**
1. ✅ Zeros are random (healthy quarters) → Don't need zero-inflation
2. ✅ Healthcare data → Almost certainly has overdispersion
3. ✅ Simple and interpretable → Easy to defend to consortium
4. ✅ Established method → Available in `flexmix` package
5. ✅ Computationally feasible → 12 hours for 400K patients

**Secondary Option: Compare Poisson and NB**

If you want to be thorough:
1. Fit Poisson first (5 min)
2. Check within-class dispersion
3. Fit NB (15 min)
4. Compare BIC

**Expected result:** NB improves BIC by 200-400 points → Use NB

**Not Recommended: ZIP or ZINB**

Unless your diagnostics show:
- >5% of patients have ALL zeros across ALL quarters
- OR clinical knowledge suggests structural barriers exist
- Then reconsider ZIP/ZINB

**For your specific data:** This is unlikely, so stick with NB.

---

## Next Steps

1. **Run diagnostics** (in the R Markdown file):
   - Check overdispersion ratio
   - Check structural zero rate
   
2. **Fit NB-GBTM** with k=4:
   - Should take ~15 minutes on 10K patient subset
   
3. **Validate results**:
   - Check BIC vs. Poisson
   - Verify posterior probabilities > 0.7
   - Ensure trajectories make clinical sense
   
4. **Scale to full data** (400K patients):
   - Run overnight (~12 hours)
   
5. **Characterize classes**:
   - Demographics
   - Clinical characteristics
   - Treatment outcomes

**You're ready to go!** Start with the `gbtm_flexible.Rmd` file and `model_type <- "nb"`.

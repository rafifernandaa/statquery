-- ============================================================
-- StatQuery: Statistical Methods Catalog
-- AlloyDB for PostgreSQL Schema
-- ============================================================

-- Enable pgvector extension (AlloyDB has this built-in)
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- Main Table: statistical_methods
-- ============================================================
CREATE TABLE IF NOT EXISTS statistical_methods (
    method_id       SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    category        TEXT NOT NULL,         -- e.g., 'Regression', 'IRT', 'SEM', 'Bayesian'
    subcategory     TEXT,                  -- e.g., 'Binary Logistic', '2PL Model'
    description     TEXT NOT NULL,
    use_case        TEXT NOT NULL,         -- when to use this method
    assumptions     TEXT,                  -- key assumptions
    min_sample_size INTEGER,               -- recommended minimum n
    data_type       TEXT,                  -- 'continuous', 'categorical', 'ordinal', 'mixed'
    software        TEXT,                  -- 'R, Python, SPSS, Stata'
    r_packages      TEXT,                  -- R packages
    python_packages TEXT,                  -- Python packages
    difficulty      TEXT,                  -- 'Beginner', 'Intermediate', 'Advanced'
    reference       TEXT,                  -- key citation
    created_at      TIMESTAMP DEFAULT NOW(),
    -- AlloyDB AI vector column for semantic search
    method_vector   vector(768)
);

-- ============================================================
-- Seed Data: 30 Statistical Methods
-- ============================================================
INSERT INTO statistical_methods
    (name, category, subcategory, description, use_case, assumptions, min_sample_size, data_type, software, r_packages, python_packages, difficulty, reference)
VALUES

-- REGRESSION METHODS
('Simple Linear Regression', 'Regression', 'OLS', 
 'Models the linear relationship between one predictor and a continuous outcome variable.',
 'Predicting a continuous outcome from a single numeric predictor; estimating effect size.',
 'Linearity, independence, homoscedasticity, normality of residuals', 30, 'continuous',
 'R, Python, SPSS, Stata', 'stats, lm()', 'statsmodels, sklearn', 'Beginner',
 'Montgomery et al. (2012). Introduction to Linear Regression Analysis.'),

('Multiple Linear Regression', 'Regression', 'OLS',
 'Extends simple regression to model outcomes from multiple predictors simultaneously.',
 'Predicting outcomes while controlling for confounders; identifying independent predictors.',
 'Linearity, no multicollinearity, homoscedasticity, normality of residuals', 50, 'continuous',
 'R, Python, SPSS, Stata', 'stats, lm()', 'statsmodels, sklearn', 'Beginner',
 'Cohen et al. (2003). Applied Multiple Regression/Correlation Analysis.'),

('Binary Logistic Regression', 'Regression', 'Logistic',
 'Models the probability of a binary outcome using a logistic function. Outputs odds ratios.',
 'Predicting categorical outcomes (pass/fail, yes/no); classification with interpretable coefficients.',
 'Independence of observations, no perfect multicollinearity, large sample size', 100, 'categorical',
 'R, Python, SPSS, Stata', 'glm(family=binomial), stats', 'statsmodels, sklearn', 'Beginner',
 'Hosmer & Lemeshow (2013). Applied Logistic Regression.'),

('Ordinal Logistic Regression', 'Regression', 'Logistic',
 'Extends logistic regression to ordered categorical outcomes (e.g., Likert scale responses).',
 'Analyzing ordered outcomes like survey ratings, education levels, or severity scores.',
 'Proportional odds assumption, independence, no perfect multicollinearity', 100, 'ordinal',
 'R, Python', 'MASS::polr(), ordinal', 'statsmodels, mord', 'Intermediate',
 'Agresti (2010). Analysis of Ordinal Categorical Data.'),

('Poisson Regression', 'Regression', 'GLM',
 'Models count data as a Poisson-distributed outcome; handles non-negative integer responses.',
 'Analyzing event counts, frequency data, or rate outcomes.',
 'Mean equals variance (equidispersion), independence, log-linear relationship', 50, 'continuous',
 'R, Python, SPSS', 'glm(family=poisson)', 'statsmodels', 'Intermediate',
 'Cameron & Trivedi (2013). Regression Analysis of Count Data.'),

('Panel Data Regression (FEM/REM)', 'Regression', 'Panel',
 'Handles longitudinal data with repeated measures across units. FEM controls for unit-specific effects.',
 'Analyzing data with repeated observations over time (e.g., country-level indicators across years).',
 'Strict exogeneity (FEM), random effects uncorrelated with predictors (REM)', 50, 'continuous',
 'R, Stata, Python', 'plm', 'linearmodels', 'Intermediate',
 'Hsiao (2014). Analysis of Panel Data.'),

('Ridge Regression', 'Regression', 'Regularized',
 'OLS with L2 penalty to handle multicollinearity; shrinks coefficients toward zero.',
 'Regression with highly correlated predictors; preventing overfitting.',
 'Same as OLS but relaxes multicollinearity constraint', 30, 'continuous',
 'R, Python', 'glmnet', 'sklearn', 'Intermediate',
 'Hoerl & Kennard (1970). Ridge Regression: Biased Estimation.'),

('LASSO Regression', 'Regression', 'Regularized',
 'OLS with L1 penalty that performs variable selection by shrinking some coefficients to exactly zero.',
 'High-dimensional data; automatic feature selection; sparse models.',
 'No strict distributional assumptions; works with many predictors', 50, 'continuous',
 'R, Python', 'glmnet', 'sklearn', 'Intermediate',
 'Tibshirani (1996). Regression Shrinkage and Selection via the Lasso.'),

-- IRT METHODS
('Rasch Model (1PL IRT)', 'IRT', '1-Parameter',
 'One-parameter IRT model estimating item difficulty and person ability on the same logit scale.',
 'Educational testing, psychometric scale development, measuring latent traits with dichotomous items.',
 'Unidimensionality, local independence, no item discrimination differences', 200, 'categorical',
 'R', 'TAM, eRm, mirt', 'girth', 'Intermediate',
 'Rasch (1960). Probabilistic Models for Intelligence and Attainment Tests.'),

('2PL IRT Model', 'IRT', '2-Parameter',
 'IRT model with item difficulty and discrimination parameters; items can differ in how well they distinguish ability levels.',
 'Scale development where items vary in discriminating power; adaptive testing.',
 'Unidimensionality, local independence, sufficient sample size', 500, 'categorical',
 'R, Python', 'mirt, ltm', 'girth, irt', 'Advanced',
 'Birnbaum (1968). Statistical theories of mental test scores.'),

('3PL IRT Model', 'IRT', '3-Parameter',
 'Adds a pseudo-guessing parameter to 2PL; models the probability that low-ability respondents guess correctly.',
 'Multiple-choice examinations where guessing is plausible.',
 'Unidimensionality, local independence, very large samples required', 1000, 'categorical',
 'R', 'mirt, irtPlay', 'None (limited support)', 'Advanced',
 'Lord (1980). Applications of Item Response Theory to Practical Testing Problems.'),

('Graded Response Model (GRM)', 'IRT', 'Polytomous',
 'IRT model for ordered polytomous items (e.g., Likert scales); estimates thresholds between categories.',
 'Psychometric analysis of rating scales, Likert-type surveys, polytomous items.',
 'Unidimensionality, local independence, ordered response categories', 300, 'ordinal',
 'R', 'mirt, ltm', 'None', 'Advanced',
 'Samejima (1969). Estimation of Latent Ability Using a Response Pattern.'),

('Differential Item Functioning (DIF)', 'IRT', 'DIF Analysis',
 'Detects items that behave differently across groups (e.g., gender, ethnicity) after controlling for ability.',
 'Fairness analysis in educational tests; identifying biased items in psychological scales.',
 'IRT model fits data; groups are comparable on the latent trait', 200, 'categorical',
 'R', 'lordif, mirt, difR', 'None', 'Advanced',
 'Millsap & Everson (1993). Methodology review: Statistical approaches for DIF.'),

-- SEM METHODS  
('Confirmatory Factor Analysis (CFA)', 'SEM', 'Measurement Model',
 'Tests whether observed variables load onto theoretically specified latent factors.',
 'Validating psychometric scales; testing measurement models before SEM.',
 'Multivariate normality (or MLR estimator), sufficient sample size, model identification', 200, 'continuous',
 'R, Python, Mplus', 'lavaan, semTools', 'semopy', 'Intermediate',
 'Brown (2015). Confirmatory Factor Analysis for Applied Research.'),

('Structural Equation Modeling (SEM)', 'SEM', 'Full SEM',
 'Combines CFA and path analysis to test complex theoretical models with latent variables.',
 'Testing mediation/moderation with latent variables; complex causal pathway modeling.',
 'Large sample, multivariate normality (or robust estimators), model identification', 200, 'continuous',
 'R, Python, Mplus', 'lavaan, semTools', 'semopy', 'Advanced',
 'Kline (2023). Principles and Practice of Structural Equation Modeling.'),

('Partial Least Squares SEM (PLS-SEM)', 'SEM', 'Variance-Based',
 'Variance-based SEM approach that works with smaller samples and non-normal data.',
 'Exploratory research; small samples; formative constructs; prediction-focused models.',
 'No distributional assumptions, minimum sample n=10x largest path block', 50, 'mixed',
 'R, SmartPLS', 'seminr, plspm', 'None', 'Intermediate',
 'Hair et al. (2022). A Primer on Partial Least Squares SEM.'),

('Mediation Analysis', 'SEM', 'Path Analysis',
 'Tests whether a third variable (mediator) explains the relationship between predictor and outcome.',
 'Mechanism testing; indirect effect estimation; process modeling.',
 'Causal assumptions, no unmeasured confounders, temporal ordering', 100, 'continuous',
 'R, SPSS (PROCESS), Python', 'mediation, manymome, lavaan', 'pingouin', 'Intermediate',
 'MacKinnon (2008). Introduction to Statistical Mediation Analysis.'),

('Moderation Analysis', 'SEM', 'Path Analysis',
 'Tests whether the relationship between two variables depends on a third variable (moderator).',
 'Identifying boundary conditions of effects; interaction testing.',
 'Linearity, no multicollinearity, independence', 100, 'continuous',
 'R, SPSS (PROCESS)', 'interactions, manymome', 'pingouin, statsmodels', 'Intermediate',
 'Hayes (2022). Introduction to Mediation, Moderation, and Conditional Process Analysis.'),

-- BAYESIAN METHODS
('Bayesian Linear Regression', 'Bayesian', 'Regression',
 'Regression framework that incorporates prior knowledge and returns posterior distributions over parameters.',
 'Small samples where priors encode domain knowledge; full uncertainty quantification.',
 'Correct prior specification; MCMC convergence', 20, 'continuous',
 'R, Python', 'brms, rstanarm', 'PyMC, bambi', 'Advanced',
 'Gelman et al. (2014). Bayesian Data Analysis.'),

('Bayesian Network', 'Bayesian', 'Graphical Model',
 'Probabilistic graphical model encoding conditional dependencies between variables as a directed acyclic graph.',
 'Causal discovery; probabilistic inference; complex dependency structures.',
 'Acyclic graph structure; correct conditional independence assumptions', 100, 'mixed',
 'R, Python', 'bnlearn, deal', 'pgmpy, pomegranate', 'Advanced',
 'Pearl (2009). Causality: Models, Reasoning and Inference.'),

-- NONPARAMETRIC METHODS
('Mann-Whitney U Test', 'Nonparametric', 'Two-Sample',
 'Nonparametric alternative to independent samples t-test; compares distributions of two groups.',
 'Comparing two independent groups when normality assumption is violated; ordinal data.',
 'Independence, ordinal or continuous data, similar distribution shapes', 20, 'ordinal',
 'R, Python, SPSS', 'stats::wilcox.test()', 'scipy.stats', 'Beginner',
 'Mann & Whitney (1947). On a test of whether one of two random variables is stochastically larger.'),

('Kruskal-Wallis Test', 'Nonparametric', 'k-Sample',
 'Nonparametric equivalent of one-way ANOVA; tests whether k independent groups come from the same distribution.',
 'Comparing three or more groups with non-normal or ordinal data.',
 'Independence, ordinal or continuous data', 20, 'ordinal',
 'R, Python, SPSS', 'stats::kruskal.test()', 'scipy.stats', 'Beginner',
 'Kruskal & Wallis (1952). Use of Ranks in One-Criterion Variance Analysis.'),

('Spearman Rank Correlation', 'Nonparametric', 'Correlation',
 'Nonparametric correlation measuring monotonic relationships using ranked data.',
 'Ordinal data correlation; non-linear monotonic relationships; outlier-robust correlation.',
 'Monotonic relationship, no tied ranks (or correction applied)', 10, 'ordinal',
 'R, Python, SPSS', 'cor(method="spearman")', 'scipy.stats.spearmanr', 'Beginner',
 'Spearman (1904). The proof and measurement of association between two things.'),

-- MULTIVARIATE METHODS
('Principal Component Analysis (PCA)', 'Multivariate', 'Dimensionality Reduction',
 'Transforms correlated variables into orthogonal principal components capturing maximum variance.',
 'Dimensionality reduction; multicollinearity removal; exploratory data visualization.',
 'Linearity, no significant outliers, sufficient sample size', 50, 'continuous',
 'R, Python', 'prcomp, FactoMineR', 'sklearn, prince', 'Beginner',
 'Jolliffe (2002). Principal Component Analysis.'),

('Exploratory Factor Analysis (EFA)', 'Multivariate', 'Factor Analysis',
 'Identifies underlying latent factors from observed variable correlations without prespecified structure.',
 'Scale development; identifying latent constructs; reducing items before CFA.',
 'Adequate sample size, sufficient correlations among items, correct factor retention', 100, 'continuous',
 'R, SPSS', 'psych::fa(), EFAutilities', 'factor_analyzer', 'Intermediate',
 'Fabrigar et al. (1999). Evaluating the use of EFA in psychological research.'),

('Cluster Analysis (K-Means)', 'Multivariate', 'Clustering',
 'Partitions observations into k clusters by minimizing within-cluster variance.',
 'Segmentation; identifying homogeneous subgroups; exploratory pattern discovery.',
 'Spherical clusters, similar cluster sizes, no significant outliers', 50, 'continuous',
 'R, Python', 'stats::kmeans()', 'sklearn', 'Beginner',
 'MacQueen (1967). Some methods for classification and analysis of multivariate observations.'),

('Discriminant Analysis (LDA)', 'Multivariate', 'Classification',
 'Finds linear combinations of features that best separate known groups; predicts group membership.',
 'Classification when groups are known; dimension reduction for categorical outcomes.',
 'Multivariate normality, equal covariance matrices, no multicollinearity', 50, 'continuous',
 'R, Python, SPSS', 'MASS::lda()', 'sklearn', 'Intermediate',
 'Fisher (1936). The use of multiple measurements in taxonomic problems.'),

-- SURVIVAL / TIME SERIES
('Kaplan-Meier Survival Analysis', 'Survival', 'Nonparametric',
 'Estimates the survival function from lifetime data, accounting for censored observations.',
 'Time-to-event data; survival rates; censored observations in medical or educational research.',
 'Independent censoring, no informative censoring', 30, 'continuous',
 'R, Python', 'survival, survminer', 'lifelines', 'Intermediate',
 'Kaplan & Meier (1958). Nonparametric estimation from incomplete observations.'),

('Cox Proportional Hazards Model', 'Survival', 'Semiparametric',
 'Semiparametric regression model for survival data; estimates hazard ratios for predictors.',
 'Modeling time-to-event outcomes with covariates; identifying risk factors.',
 'Proportional hazards assumption, independence, no tied event times', 50, 'continuous',
 'R, Python', 'survival, coxphf', 'lifelines, sksurv', 'Advanced',
 'Cox (1972). Regression models and life-tables.'),

('ARIMA Time Series', 'Time Series', 'Forecasting',
 'Autoregressive Integrated Moving Average model for stationary time series forecasting.',
 'Forecasting univariate time series; decomposing trend, seasonality, and noise.',
 'Stationarity (or differencing), no structural breaks, adequate time points', 50, 'continuous',
 'R, Python', 'forecast, tseries', 'statsmodels, pmdarima', 'Intermediate',
 'Box & Jenkins (1976). Time Series Analysis: Forecasting and Control.');

-- ============================================================
-- Generate AlloyDB AI vector embeddings for all rows
-- Run this AFTER inserting data
-- ============================================================
UPDATE statistical_methods
SET method_vector = embedding('text-embedding-005',
    name || ' ' || category || ' ' || description || ' ' || use_case
)::vector
WHERE method_vector IS NULL;

-- ============================================================
-- Enable AlloyDB AI Natural Language (run via AlloyDB Studio)
-- ============================================================
-- CALL google_ml_integration.create_model_config(
--   model_id => 'gemini-2.0-flash',
--   model_provider => 'google',
--   model_type => 'text',
--   model_endpoint => 'https://aiplatform.googleapis.com/v1/projects/my-project-31-491314/locations/us-central1/publishers/google/models/gemini-2.0-flash:generateContent'
-- );

-- ============================================================
-- Useful index for vector similarity search
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_method_vector
ON statistical_methods
USING ivfflat (method_vector vector_cosine_ops)
WITH (lists = 10);

-- ============================================================
-- Query Log Table (tracks natural language queries)
-- ============================================================
CREATE TABLE IF NOT EXISTS query_log (
    log_id      SERIAL PRIMARY KEY,
    nl_query    TEXT NOT NULL,
    sql_query   TEXT,
    result_count INTEGER,
    queried_at  TIMESTAMP DEFAULT NOW()
);

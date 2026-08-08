# Data Engineering Project

A Databricks Asset Bundle (DAB) that implements a Bronze → Silver → Gold
medallion pipeline for customer, product, sales, and supplier data, with
row/column-level governance on top. Deploys as Databricks Jobs across `dev`,
`uat`, and `prod` targets from a single codebase.

## Architecture

```
                     ┌────────────┐
                     │ cat_schema │  creates catalogs/schemas/volumes
                     └─────┬──────┘
        ┌──────────┬───────┼───────┬──────────┐
        ▼          ▼       ▼       ▼
   customer_data  products_data  sales_data  suppliers_data   (spark_python_task)
        └──────────┴───────┴───────┴──────────┘
                     ▼
              ingestion_to_bronze        (notebook_task → bronze tables via COPY INTO)
                     ▼
        ┌──────────┬───────┬──────────┐
        ▼          ▼       ▼          ▼
  customer_clean  products_scd2  sales_clean  supplier_clean   (silver, sql_task)
        └──────────┴───────┴──────────┘
                     ▼
   customer_last_purchase, customer_metrics, daily_kpis,
   sales_summary, product_analytics                            (gold, sql_task)
```

### Bronze layer
Four Python tasks (`src/bronze/load_customers.py`, `load_products.py`,
`load_sales.py`, `load_suppliers.py`) generate synthetic sample data with
intentional data-quality issues — NULLs, duplicate keys, orphan foreign keys —
and write it as CSV to a Unity Catalog Volume
(`/Volumes/<catalog>/bronze/raw/...`). Each script takes the target catalog
via a `--catalog` command-line argument.

The notebook `src/ingestion to bronze.ipynb` then creates the bronze Delta
tables (`customers_raw`, `products_raw`, `sales_raw`, `suppliers_raw`) and
loads the CSVs into them with `COPY INTO`.

### Silver layer
SQL tasks clean and conform the bronze tables:
- `silver/scd_type1_customers.sql` — dedupes and applies SCD Type 1 to customers
- `silver/scd_type2_products.sql` — applies SCD Type 2 versioning to products
- `silver/Sales.sql` — cleans and validates sales records
- `silver/suppliers.sql` — cleans supplier records

### Gold layer
SQL tasks build reporting views/tables on top of silver:
- `gold/customer_last_purchase.sql`
- `gold/customer_metrics.sql`
- `gold/daily_kpis.sql`
- `gold/sales_summary.sql`
- `gold/product_analytics.sql`

### Governance
`src/governance/create_secured_views.sql` builds row/column-masked views
`src/governance/Comments.sql` applies table/column tags
(`pii_level`, `data_classification`) and documentation comments. These are
not currently attached to a job task — run manually via a SQL warehouse when
needed.

## Repo layout

```
data_engineering_project/
├── databricks.yml                 # bundle + target (dev/uat/prod) definitions
├── pyproject.toml                 # local Python deps (pytest, ruff, databricks-connect, etc.)
├── AGENTS.md / CLAUDE.md          # instructions for AI coding agents working in this repo
├── resources/
│   ├── master_job.job.yml         # end-to-end job: bronze → silver → gold
│   └── jobs/
│       ├── bronze_ingestion.job.yml     # bronze layer only (standalone)
│       ├── silver_cdc_job.job.yml       # silver layer only (standalone)
│       └── gold_aggregation_job.job.yml # gold layer only (standalone)
├── src/
│   ├── cat_schema.sql             # creates catalogs/schemas/volumes for all envs
│   ├── bronze/                    # synthetic data generator scripts (spark_python_task)
│   ├── ingestion to bronze.ipynb  # bronze CSV → Delta table loader (notebook_task)
│   ├── silver/                    # cleaning / SCD SQL
│   ├── gold/                      # reporting SQL
│   └── governance/                # secured views, tags, table comments
└── fixtures/                      # test fixtures 
```

## Prerequisites

- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/databricks-cli.html)
- Access to the target Databricks workspace(s)
- A Unity Catalog SQL warehouse (referenced by `warehouse_id` in the job YAMLs)

## Environments

| Target | Mode        | Catalog    | Job name prefix |
|--------|-------------|------------|------------------|
| `dev`  | development | `dev_dep`  | `[dev_dep] `     |
| `uat`  | production  | `uat_dep`  | `[uat_dep] `     |
| `prod` | production  | `prod_dep` | `[prod_dep] `    |

The `catalog` value is declared once as a bundle variable
(`variables.catalog` in `databricks.yml`) and overridden per target. At
deploy time it flows into every task: Python tasks receive it as a
`--catalog` CLI argument, the notebook task receives it via
`base_parameters`, and SQL tasks are intended to receive it via `parameters`
bound to the `:catalog` marker used throughout the `.sql` files (see
**Known gaps** below).

## Setup

```bash
# authenticate to your workspace
databricks configure
```

Update `workspace.host` and the `root_path` user path in `databricks.yml` if
deploying under a different account than
`agrawaldeepak386@gmail.com`.

## Deploying

```bash
# deploy to dev (default target)
databricks bundle deploy -t dev

# deploy to uat
databricks bundle deploy -t uat

# deploy to prod
databricks bundle deploy -t prod
```

## Running

```bash
# run the full end-to-end pipeline in a given target
databricks bundle run master_job -t dev

# or run a single layer independently
databricks bundle run bronze_ingestion_job -t dev
databricks bundle run silver_cdc_job -t dev
databricks bundle run gold_aggregation_job -t dev
```

## Known gaps / follow-ups

- **SQL tasks don't receive `:catalog` yet.** All silver/gold `.sql` files
  reference `:catalog` (with a `COALESCE(NULLIF(:catalog,''),'dev_dep')`
  fallback), but the `sql_task` blocks in `master_job.job.yml`,
  `silver_cdc_job.job.yml`, and `gold_aggregation_job.job.yml` don't pass a
  `parameters:` block yet — so every environment currently falls back to
  writing into the `dev_dep` catalog. Fix by adding, to each `sql_task`:
  ```yaml
  parameters:
    catalog: "{{job.parameters.catalog}}"
  ```
- **Notebook's row-count cell is hardcoded to `dev`.** The last cell in
  `src/ingestion to bronze.ipynb` queries `dev_dep.bronze.{tbl}` directly instead
  of using the `catalog` widget value already defined earlier in the
  notebook.
- **`governance/Comments.sql` mixes parameterized and hardcoded catalog
  references** — the `COMMENT ON TABLE` at the top uses `:catalog`, but the
  `ALTER TABLE` tag statements below hardcode `dev_dep.silver...` /
  `dev_dep.gold...`.
- **`cat_schema.sql` creates all three catalogs** (`dev_dep`, `uat_dep`,
  `prod_dep`) in one script rather than only the one being deployed —
  fine for one-time setup, but means every environment's `cat_schema` task
  re-runs `CREATE CATALOG IF NOT EXISTS` for all three.
- Governance SQL is not yet wired into any job — attach as a task if
  automated tagging/secured-view refresh is needed.
# Complete Implementation Steps: People Operations Demo

## Project Metadata
- **GCP Project:** `people-ops-demo`
- **BigQuery Location:** `US` (multi-region)
- **Dataset Name:** `people_ops`
- **Target Looker Region:** `us-central1`
- **Edition:** Looker (Google Cloud core) Standard Edition
- **Timestamp:** October 2026

---

## Step 1: Authentication & Environment Setup
- Authenticated against Google Cloud using Application Default Credentials (ADC) associated with `liorginz@google.com`.
- Verified access tokens and project configuration for `people-ops-demo`.
- Configured REST-based API interaction pipeline to interact with BigQuery, Dataplex, and Looker APIs.

---

## Step 2: BigQuery Dataset Creation
Created dataset `people_ops` in multi-region `US` with governance labels and executive description:
- **Dataset ID:** `people-ops-demo:people_ops`
- **Location:** `US`
- **Friendly Name:** `People Operations Analytics & HR Data Warehouse`
- **Description:** *"Unified People Operations and Human Capital Management analytics dataset containing core employee lifecycle, departmental hierarchy, compensation, performance reviews, attrition records, and learning development data for enterprise HR reporting and Conversational Analytics."*
- **Labels:**
  - `business_domain`: `people_operations`
  - `tier`: `enterprise_reporting`
  - `data_governance`: `internal_confidential`

---

## Step 3: Schema Design with Rich Descriptions
Designed 7 relational tables with field-level and table-level `description` attributes (essential for Dataplex Knowledge Catalog indexing):

| Table | Description | Key Fields | Descriptions Populated |
| :--- | :--- | :--- | :--- |
| `departments` | Master department registry, budgets, HQ | `department_id`, `department_name`, `division`, `headcount_budget` | All 7 columns |
| `jobs` | Job catalog, pay bands, leveling | `job_id`, `job_title`, `job_level`, `min_salary`, `max_salary` | All 9 columns |
| `employees` | Core employee master registry | `employee_id`, `hire_date`, `department_id`, `job_id`, `manager_id`, `gender` | All 14 columns |
| `compensation` | Salary, target bonus, equity grants | `compensation_id`, `employee_id`, `base_salary`, `equity_grant_usd` | All 8 columns |
| `performance_reviews` | Review cycles, calibrated ratings, OKRs | `review_id`, `employee_id`, `overall_rating`, `goal_completion_pct` | All 10 columns |
| `attrition_exits` | Turnover records, exit drivers, regrets | `exit_id`, `employee_id`, `exit_type`, `primary_exit_reason`, `tenure_years` | All 8 columns |
| `training_programs` | L&D enrollment, certifications, scores | `training_id`, `employee_id`, `course_name`, `completion_status`, `score_pct` | All 9 columns |

---

## Step 4: Synthetic Data Ingestion (>= 50 Rows per Table)
Developed automated generator script (`/home/liorginz/some/people_ops_demo/setup_bigquery.py`) and populated BigQuery tables via streaming insert:

```bash
python3 /home/liorginz/some/people_ops_demo/setup_bigquery.py
```

### Verified Ingested Row Counts:
- `departments`: **52 rows**
- `jobs`: **54 rows**
- `employees`: **75 rows**
- `compensation`: **75 rows**
- `performance_reviews`: **75 rows**
- `attrition_exits`: **52 rows**
- `training_programs`: **75 rows**

All relational foreign keys (`department_id`, `job_id`, `employee_id`, `manager_id`) join cleanly across tables without orphan records.

---

## Step 5: Knowledge Catalog & Dataplex Auto-Indexing Verification
1. Verified that APIs are enabled:
   - `dataplex.googleapis.com`: **ENABLED**
   - `datacatalog.googleapis.com`: **ENABLED**
2. Verified Dataplex Universal Catalog `@bigquery` entry group in region `US`:
   ```text
   projects/people-ops-demo/locations/us/entryGroups/@bigquery
   ```
3. Queried Dataplex entries for `people_ops`:
   ```text
   projects/people-ops-demo/locations/us/entryGroups/@bigquery/entries/bigquery.googleapis.com/projects/people-ops-demo/datasets/people_ops/tables/employees
   ```
   *Result:* All 7 tables and their column descriptions are automatically registered in the Dataplex Knowledge Catalog.

---

## Step 6: Looker Instance Creation & Quota Resolution

### API Creation Execution:
Invoked Looker v1 API to provision a Standard edition instance:
- **Endpoint:** `POST https://looker.googleapis.com/v1/projects/people-ops-demo/locations/us-central1/instances?instanceId=looker-people-ops`
- **Payload:**
  ```json
  {
    "platformEdition": "LOOKER_CORE_STANDARD",
    "publicIpEnabled": true,
    "geminiEnabled": true,
    "oauthConfig": {
      "sharedOauthClientEnabled": true
    }
  }
  ```

### Quota Diagnosis:
The API returned:
```json
{
  "error": {
    "code": 429,
    "message": "Quota limit 'StandardInstancesPerProjectPerRegion' has been exceeded. Limit: 0 in region us-central1.",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

### Analysis & Resolution:
1. The global quota `looker.googleapis.com/instances` is set to 3.
2. However, the edition-specific quota `StandardInstancesPerProjectPerRegion` defaults to `0` until a Looker contract/subscription is linked to the billing account, or an increase is requested.
3. **To enable in GCP Console:**
   - Go to **IAM & Admin > Quotas & System Limits**
   - Filter by Service: **Looker API**
   - Select **Looker Standard instances per project per region** (`StandardInstancesPerProjectPerRegion`) in `us-central1`
   - Click **Edit Quotas**, request limit increase to `1`, and provide business justification.
4. Once approved, the instance can be deployed immediately with:
   ```bash
   gcloud looker instances create looker-people-ops \
     --project=people-ops-demo \
     --region=us-central1 \
     --public-ip-enabled
   ```

---

## Step 7 & 8: LookML Models, 8 Core Business Metrics & Views
Created complete production LookML project files under `/home/liorginz/some/people_ops_demo/looker/`:
- `models/people_ops.model.lkml`: Configured base explore `employees` and defined standard joins to all 6 supporting tables.
- `views/*.view.lkml`: 7 views with dimensions, dimension groups, primary keys, and measures.
- **8 LookML Business Metrics:**
  1. `attrition_rate` (Employees LEFT JOIN Attrition Exits)
  2. `regrettable_attrition_rate` (Employees LEFT JOIN Attrition Exits)
  3. `gender_pay_equity_ratio` (Employees LEFT JOIN Compensation)
  4. `average_compa_ratio` (Employees LEFT JOIN Compensation LEFT JOIN Jobs)
  5. `headcount_budget_variance` (Departments LEFT JOIN Employees)
  6. `high_performer_retention_rate` (Employees LEFT JOIN Reviews LEFT JOIN Attrition Exits)
  7. `training_completion_efficiency` (Employees LEFT JOIN Training Programs)
  8. `total_workforce_investment` (Employees LEFT JOIN Compensation)

---

## Step 9: Fancy LookML Executive Dashboard
Authored `people_ops_executive_dashboard.dashboard.lookml`:
- Newspaper grid layout with responsive dimensions.
- 6 single-value KPI metric summary cards across row 0.
- 6 graphical visual tiles:
  - Headcount & Department Allocation (bar chart)
  - Base Salary Equity by Career Level & Gender (column chart)
  - Primary Voluntary Departure Drivers (donut chart)
  - Performance Rating vs Base Salary Distribution (scatter plot)
  - Learning & Development Completion by Category (dual-axis column/line)
  - Top Performer Calibration & Retention Watchlist (styled data table with continuous color scale)
- Global dashboard field filters for `division` and `work_location`.

---

## Step 10 & 11: Conversational Analytics User Guide & Demo Documentation
- Authored **End-User Guide** (`docs/USER_GUIDE_CONVERSATIONAL_ANALYTICS.md`) detailing query processing flow, architecture sequence diagrams, and 5 complete natural language prompts with end-to-end SQL traces.
- Authored this implementation audit log (`docs/DEMO_CREATION_STEPS.md`).
- Published both documents as interactive system artifacts.


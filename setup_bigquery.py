#!/usr/bin/env python3
"""
Sets up the BigQuery `people_ops` dataset and core People Operations tables
with schemas, comprehensive descriptions, and synthetic data (>= 50 rows each).
"""

import json
import subprocess
import urllib.request
import urllib.error
from datetime import date, timedelta
import random

import sys

def get_active_project():
    if len(sys.argv) > 1:
        return sys.argv[1]
    cmd = ["gcloud", "config", "get-value", "project"]
    return subprocess.check_output(cmd).decode().strip()

PROJECT_ID = get_active_project()
DATASET_ID = "people_ops"
LOCATION = "US"


def get_access_token():
    cmd = ["gcloud", "auth", "application-default", "print-access-token"]
    return subprocess.check_output(cmd).decode().strip()

def bq_request(endpoint, method="GET", body=None, token=None):
    if not token:
        token = get_access_token()
    url = f"https://bigquery.googleapis.com/bigquery/v2/projects/{PROJECT_ID}/{endpoint}"
    data = json.dumps(body).encode("utf-8") if body else None
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        print(f"Error on {method} {url}: {e.code} - {err_msg}")
        raise

def create_dataset_if_not_exists(token):
    dataset_body = {
        "datasetReference": {
            "datasetId": DATASET_ID,
            "projectId": PROJECT_ID
        },
        "location": LOCATION,
        "friendlyName": "People Operations Analytics & HR Data Warehouse",
        "description": "Unified People Operations and Human Capital Management analytics dataset containing core employee lifecycle, departmental hierarchy, compensation, performance reviews, attrition records, and learning development data for enterprise HR reporting and Conversational Analytics.",
        "labels": {
            "business_domain": "people_operations",
            "tier": "enterprise_reporting",
            "data_governance": "internal_confidential"
        }
    }
    try:
        bq_request(f"datasets/{DATASET_ID}", method="GET", token=token)
        print(f"Dataset {DATASET_ID} already exists. Updating metadata...")
        bq_request(f"datasets/{DATASET_ID}", method="PUT", body=dataset_body, token=token)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"Creating dataset {DATASET_ID} in {LOCATION}...")
            bq_request("datasets", method="POST", body=dataset_body, token=token)
            print(f"Dataset {DATASET_ID} created successfully.")
        else:
            raise

def create_table(table_id, description, schema_fields, token):
    table_body = {
        "tableReference": {
            "projectId": PROJECT_ID,
            "datasetId": DATASET_ID,
            "tableId": table_id
        },
        "description": description,
        "schema": {
            "fields": schema_fields
        }
    }
    # Check if table exists
    try:
        bq_request(f"datasets/{DATASET_ID}/tables/{table_id}", method="DELETE", token=token)
        print(f"Deleted existing table {table_id} for clean reload.")
    except urllib.error.HTTPError:
        pass

    print(f"Creating table {table_id}...")
    bq_request(f"datasets/{DATASET_ID}/tables", method="POST", body=table_body, token=token)
    print(f"Table {table_id} created.")

def insert_rows(table_id, rows, token):
    print(f"Inserting {len(rows)} rows into {table_id}...")
    # BQ insertAll streaming endpoint
    body = {
        "rows": [{"json": r} for r in rows]
    }
    resp = bq_request(f"datasets/{DATASET_ID}/tables/{table_id}/insertAll", method="POST", body=body, token=token)
    if "insertErrors" in resp and resp["insertErrors"]:
        print(f"Insert errors in {table_id}:", resp["insertErrors"][:3])
        raise Exception(f"Failed to insert into {table_id}")
    print(f"Successfully inserted {len(rows)} rows into {table_id}.")

def main():
    token = get_access_token()
    create_dataset_if_not_exists(token)

    # 1. Departments Table Schema
    dept_schema = [
        {"name": "department_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique identifier for the department (e.g., D-101). Primary key."},
        {"name": "department_name", "type": "STRING", "mode": "REQUIRED", "description": "Business department title (e.g., Engineering, Sales, Product Management)."},
        {"name": "division", "type": "STRING", "mode": "REQUIRED", "description": "High-level corporate division (e.g., Technology, Commercial, Corporate Functions)."},
        {"name": "cost_center", "type": "STRING", "mode": "REQUIRED", "description": "Financial cost center code allocated for budgeting and operational expenses."},
        {"name": "headcount_budget", "type": "INTEGER", "mode": "NULLABLE", "description": "Approved annual full-time employee (FTE) headcount quota for the department."},
        {"name": "location_headquarters", "type": "STRING", "mode": "NULLABLE", "description": "Primary regional office or city location where the department leadership resides."},
        {"name": "lead_manager_id", "type": "STRING", "mode": "NULLABLE", "description": "Employee ID of the senior director or vice president leading this department."}
    ]

    # 2. Jobs Table Schema
    jobs_schema = [
        {"name": "job_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique identifier for the job profile (e.g., JOB-201). Primary key."},
        {"name": "job_title", "type": "STRING", "mode": "REQUIRED", "description": "Official job title for the role (e.g., Senior Software Engineer)."},
        {"name": "job_family", "type": "STRING", "mode": "REQUIRED", "description": "Functional domain grouping (e.g., Software Engineering, Data Science, Product, People)."},
        {"name": "job_level", "type": "STRING", "mode": "REQUIRED", "description": "Career ladder grade/level (e.g., L3 Junior, L4 Mid, L5 Senior, L6 Staff, L7 Principal)."},
        {"name": "department_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key referencing the owning department in `departments`."},
        {"name": "min_salary", "type": "NUMERIC", "mode": "REQUIRED", "description": "Lower bound of the approved annual base salary pay band in USD."},
        {"name": "max_salary", "type": "NUMERIC", "mode": "REQUIRED", "description": "Upper bound of the approved annual base salary pay band in USD."},
        {"name": "target_bonus_pct", "type": "NUMERIC", "mode": "NULLABLE", "description": "Target annual incentive performance bonus percentage of base salary."},
        {"name": "is_managerial", "type": "BOOLEAN", "mode": "REQUIRED", "description": "Flag indicating if the role involves direct people management responsibilities."}
    ]

    # 3. Employees Table Schema
    emp_schema = [
        {"name": "employee_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique corporate employee identifier (e.g., EMP-1001). Primary key."},
        {"name": "first_name", "type": "STRING", "mode": "REQUIRED", "description": "Legal first name of the employee."},
        {"name": "last_name", "type": "STRING", "mode": "REQUIRED", "description": "Legal family name of the employee."},
        {"name": "email", "type": "STRING", "mode": "REQUIRED", "description": "Corporate email address of the employee."},
        {"name": "hire_date", "type": "DATE", "mode": "REQUIRED", "description": "Calendar date when the employee formally joined the organization."},
        {"name": "department_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key joining to `departments.department_id`."},
        {"name": "job_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key joining to `jobs.job_id`."},
        {"name": "manager_id", "type": "STRING", "mode": "NULLABLE", "description": "Employee ID of direct reporting manager. Self-referencing key to `employees.employee_id`."},
        {"name": "employment_status", "type": "STRING", "mode": "REQUIRED", "description": "Current lifecycle status: 'Active', 'Terminated', 'On Leave'."},
        {"name": "employment_type", "type": "STRING", "mode": "REQUIRED", "description": "Employment categorization: 'Full-Time', 'Part-Time', 'Contract'."},
        {"name": "work_location", "type": "STRING", "mode": "REQUIRED", "description": "Assigned geographical office site or 'Remote'."},
        {"name": "education_level", "type": "STRING", "mode": "NULLABLE", "description": "Highest formal educational credential attained (Bachelors, Masters, PhD)."},
        {"name": "gender", "type": "STRING", "mode": "NULLABLE", "description": "Self-reported gender demographic identity for diversity analytics."},
        {"name": "ethnicity", "type": "STRING", "mode": "NULLABLE", "description": "Self-reported ethnic background for workforce diversity reporting."}
    ]

    # 4. Compensation Table Schema
    comp_schema = [
        {"name": "compensation_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique record key for salary/bonus event (e.g., COMP-5001). Primary key."},
        {"name": "employee_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key referencing `employees.employee_id`."},
        {"name": "effective_date", "type": "DATE", "mode": "REQUIRED", "description": "Calendar date from which this compensation adjustment took effect."},
        {"name": "base_salary", "type": "NUMERIC", "mode": "REQUIRED", "description": "Annualized base compensation amount in USD."},
        {"name": "bonus_target_amount", "type": "NUMERIC", "mode": "NULLABLE", "description": "Target cash bonus opportunity based on annual performance."},
        {"name": "equity_grant_usd", "type": "NUMERIC", "mode": "NULLABLE", "description": "Fair market value of annual restricted stock unit (RSU) equity grant."},
        {"name": "currency", "type": "STRING", "mode": "REQUIRED", "description": "Currency code for compensation (e.g., USD)."},
        {"name": "change_reason", "type": "STRING", "mode": "REQUIRED", "description": "Reason for compensation event: 'New Hire', 'Annual Merit', 'Promotion', 'Market Adjustment'."}
    ]

    # 5. Performance Reviews Table Schema
    perf_schema = [
        {"name": "review_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique evaluation identifier (e.g., REV-8001). Primary key."},
        {"name": "employee_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key referencing `employees.employee_id`."},
        {"name": "review_cycle", "type": "STRING", "mode": "REQUIRED", "description": "Fiscal performance review cycle (e.g., 2024-H2, 2025-H1)."},
        {"name": "review_date", "type": "DATE", "mode": "REQUIRED", "description": "Calendar date when the review was finalized and submitted by manager."},
        {"name": "overall_rating", "type": "NUMERIC", "mode": "REQUIRED", "description": "Overall calibrated performance rating on a 1.0 to 5.0 scale (5=Exceeds Expectations)."},
        {"name": "leadership_score", "type": "NUMERIC", "mode": "NULLABLE", "description": "Assessed score for leadership competencies and team collaboration (1.0 to 5.0)."},
        {"name": "technical_score", "type": "NUMERIC", "mode": "NULLABLE", "description": "Assessed score for technical excellence, execution speed, and quality (1.0 to 5.0)."},
        {"name": "goal_completion_pct", "type": "NUMERIC", "mode": "REQUIRED", "description": "Percentage of OKRs and individual milestones completed (0 to 100)."},
        {"name": "promotion_recommendation", "type": "BOOLEAN", "mode": "REQUIRED", "description": "Indicates whether the manager recommended the employee for promotion in this cycle."},
        {"name": "manager_feedback_summary", "type": "STRING", "mode": "NULLABLE", "description": "Executive qualitative evaluation summary and growth guidance from manager."}
    ]

    # 6. Attrition / Exits Table Schema
    attr_schema = [
        {"name": "exit_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique exit event identifier (e.g., EXIT-3001). Primary key."},
        {"name": "employee_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key referencing `employees.employee_id`."},
        {"name": "exit_date", "type": "DATE", "mode": "REQUIRED", "description": "Official last day of employment."},
        {"name": "exit_type", "type": "STRING", "mode": "REQUIRED", "description": "Separation classification: 'Voluntary' (resignation) or 'Involuntary' (layoff/termination)."},
        {"name": "primary_exit_reason", "type": "STRING", "mode": "REQUIRED", "description": "Categorized driver behind departure: 'Compensation', 'Career Opportunity', 'Relocation', 'Work-Life Balance', 'Leadership Alignment'."},
        {"name": "tenure_years", "type": "NUMERIC", "mode": "REQUIRED", "description": "Total length of service at the company in years at departure."},
        {"name": "eligible_for_rehire", "type": "BOOLEAN", "mode": "REQUIRED", "description": "HR clearance determination whether the individual is eligible for future employment."},
        {"name": "regrettable_attrition", "type": "BOOLEAN", "mode": "REQUIRED", "description": "High-performer attrition flag indicating a significant loss of critical talent."}
    ]

    # 7. Training & Development Table Schema
    train_schema = [
        {"name": "training_id", "type": "STRING", "mode": "REQUIRED", "description": "Unique training enrollment record identifier (e.g., TRN-9001). Primary key."},
        {"name": "employee_id", "type": "STRING", "mode": "REQUIRED", "description": "Foreign key referencing `employees.employee_id`."},
        {"name": "course_id", "type": "STRING", "mode": "REQUIRED", "description": "Course catalog identifier."},
        {"name": "course_name", "type": "STRING", "mode": "REQUIRED", "description": "Official title of the training program or professional certification."},
        {"name": "category", "type": "STRING", "mode": "REQUIRED", "description": "Training domain: 'Leadership', 'Cloud & AI Architecture', 'Data Analytics', 'Security & Compliance'."},
        {"name": "completion_date", "type": "DATE", "mode": "NULLABLE", "description": "Date course was passed and verified."},
        {"name": "completion_status", "type": "STRING", "mode": "REQUIRED", "description": "Status: 'Completed', 'In Progress', 'Overdue'."},
        {"name": "score_pct", "type": "NUMERIC", "mode": "NULLABLE", "description": "Assessment grade achieved upon completion (0 to 100)."},
        {"name": "credits_earned", "type": "INTEGER", "mode": "NULLABLE", "description": "Continuing education units (CEU) or learning credits awarded."}
    ]

    tables = [
        ("departments", "Master department organization registry tracking cost centers, leadership, headcount budgets, and regional HQ locations.", dept_schema),
        ("jobs", "Job family and leveling catalog establishing compensation benchmarks, management status, and departmental alignment.", jobs_schema),
        ("employees", "Core employee master table tracking employment status, career hierarchy, job assignments, work locations, and demographic attributes.", emp_schema),
        ("compensation", "Historical and current compensation ledger tracking annualized base salary, bonus incentives, equity grants, and merit adjustments.", comp_schema),
        ("performance_reviews", "Semi-annual performance evaluation records capturing calibrated ratings, goal completion rates, and promotion nominations.", perf_schema),
        ("attrition_exits", "Workforce exit records documenting turnover reasons, service tenure, regrettable losses, and rehire eligibility.", attr_schema),
        ("training_programs", "Employee learning and development registry logging continuous education, technical certifications, and compliance course completions.", train_schema)
    ]

    for tbl_id, desc, fields in tables:
        create_table(tbl_id, desc, fields, token)

    # Now generate synthetic data (>= 50 rows each with consistent keys)
    random.seed(42)

    # 1. Generate Departments (50 rows)
    dept_names = [
        ("Engineering", "Technology", "CC-101", "Mountain View, CA"),
        ("Product Management", "Technology", "CC-102", "San Francisco, CA"),
        ("Data & Analytics", "Technology", "CC-103", "Sunnyvale, CA"),
        ("Cloud Infrastructure", "Technology", "CC-104", "Seattle, WA"),
        ("Information Security", "Technology", "CC-105", "San Jose, CA"),
        ("Quality Assurance", "Technology", "CC-106", "Austin, TX"),
        ("Enterprise Sales", "Commercial", "CC-201", "New York, NY"),
        ("Mid-Market Sales", "Commercial", "CC-202", "Chicago, IL"),
        ("Customer Success", "Commercial", "CC-203", "Atlanta, GA"),
        ("Sales Engineering", "Commercial", "CC-204", "Boston, MA"),
        ("Digital Marketing", "Commercial", "CC-205", "Los Angeles, CA"),
        ("Brand & Communications", "Commercial", "CC-206", "New York, NY"),
        ("People Operations & HR", "Corporate Functions", "CC-301", "Sunnyvale, CA"),
        ("Talent Acquisition", "Corporate Functions", "CC-302", "Austin, TX"),
        ("Total Rewards & Benefits", "Corporate Functions", "CC-303", "San Francisco, CA"),
        ("Learning & Organizational Development", "Corporate Functions", "CC-304", "Seattle, WA"),
        ("Corporate Finance & FP&A", "Corporate Functions", "CC-401", "New York, NY"),
        ("Accounting & Tax", "Corporate Functions", "CC-402", "Denver, CO"),
        ("Legal, Compliance & Ethics", "Corporate Functions", "CC-403", "Washington, DC"),
        ("Procurement & Real Estate", "Corporate Functions", "CC-404", "Dallas, TX")
    ]
    # Expand to 52 departments to satisfy >= 50 requirement
    departments_data = []
    for i in range(1, 53):
        base = dept_names[(i - 1) % len(dept_names)]
        suffix = f" {((i - 1) // len(dept_names)) + 1}" if i > len(dept_names) else ""
        dept_id = f"DEPT-{i:03d}"
        departments_data.append({
            "department_id": dept_id,
            "department_name": f"{base[0]}{suffix}",
            "division": base[1],
            "cost_center": f"{base[2]}-{(i%10):02d}",
            "headcount_budget": random.randint(15, 80),
            "location_headquarters": base[3],
            "lead_manager_id": f"EMP-{(1000 + i):04d}"
        })
    insert_rows("departments", departments_data, token)

    # 2. Generate Jobs (52 rows)
    job_templates = [
        ("Software Engineer", "Software Engineering", "L3", 110000, 150000, 10, False),
        ("Senior Software Engineer", "Software Engineering", "L5", 160000, 220000, 15, False),
        ("Staff Software Engineer", "Software Engineering", "L6", 210000, 280000, 20, False),
        ("Engineering Manager", "Software Engineering", "M1", 190000, 260000, 20, True),
        ("Data Engineer", "Data & Analytics", "L4", 130000, 175000, 12, False),
        ("Senior Data Scientist", "Data & Analytics", "L5", 165000, 230000, 15, False),
        ("Analytics Manager", "Data & Analytics", "M1", 185000, 250000, 20, True),
        ("Product Manager", "Product Management", "L4", 135000, 180000, 15, False),
        ("Senior Product Manager", "Product Management", "L5", 170000, 235000, 18, False),
        ("Director of Product", "Product Management", "M2", 230000, 310000, 25, True),
        ("Account Executive", "Sales", "L4", 95000, 140000, 30, False),
        ("Enterprise Account Director", "Sales", "L6", 150000, 210000, 40, False),
        ("Sales Manager", "Sales", "M1", 160000, 220000, 35, True),
        ("Customer Success Manager", "Customer Success", "L3", 85000, 120000, 10, False),
        ("Security Analyst", "Information Security", "L3", 95000, 135000, 10, False),
        ("People Ops Business Partner", "People Operations", "L4", 110000, 150000, 12, False),
        ("Talent Acquisition Partner", "Talent Acquisition", "L3", 85000, 120000, 10, False),
        ("Financial Analyst", "Finance", "L3", 90000, 125000, 10, False),
        ("Corporate Counsel", "Legal", "L5", 175000, 240000, 15, False)
    ]
    jobs_data = []
    for i in range(1, 55):
        tmpl = job_templates[(i - 1) % len(job_templates)]
        dept_ref = departments_data[(i - 1) % len(departments_data)]["department_id"]
        job_id = f"JOB-{i:03d}"
        jobs_data.append({
            "job_id": job_id,
            "job_title": f"{tmpl[0]} {'Specialist' if i > 30 else ''}".strip(),
            "job_family": tmpl[1],
            "job_level": tmpl[2],
            "department_id": dept_ref,
            "min_salary": str(tmpl[3]),
            "max_salary": str(tmpl[4]),
            "target_bonus_pct": str(tmpl[5]),
            "is_managerial": tmpl[6]
        })
    insert_rows("jobs", jobs_data, token)

    # 3. Generate Employees (75 rows)
    first_names = ["Alex", "Jordan", "Taylor", "Morgan", "Sam", "Chris", "Pat", "Casey", "Riley", "Avery",
                   "Cameron", "Dakota", "Reese", "Quinn", "Rowan", "Hayden", "Logan", "Jesse", "Finley", "Emerson",
                   "Maya", "Liam", "Noah", "Olivia", "Emma", "Ava", "Sophia", "Lucas", "Oliver", "Ethan"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
                  "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
                  "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson"]
    locations = ["Mountain View, CA", "San Francisco, CA", "Sunnyvale, CA", "Seattle, WA", "New York, NY", "Austin, TX", "Remote"]
    educations = ["Bachelors", "Masters", "PhD", "Associates"]
    genders = ["Female", "Male", "Non-Binary"]
    ethnicities = ["Asian", "Hispanic/Latino", "White", "Black/African American", "Two or More Races"]

    employees_data = []
    base_hire_date = date(2019, 1, 15)

    for i in range(1, 76):
        emp_id = f"EMP-{1000 + i}"
        fn = first_names[(i - 1) % len(first_names)]
        ln = last_names[(i * 3) % len(last_names)]
        email = f"{fn.lower()}.{ln.lower()}{i}@examplecorp.com"
        h_date = base_hire_date + timedelta(days=(i * 35))
        dept_id = departments_data[(i - 1) % len(departments_data)]["department_id"]
        job = jobs_data[(i - 1) % len(jobs_data)]
        mgr_id = f"EMP-{1001 + (i % 5)}" if i > 5 else None
        status = "Terminated" if i in [7, 14, 22, 33, 45, 58, 67] else ("On Leave" if i in [11, 29, 51] else "Active")

        employees_data.append({
            "employee_id": emp_id,
            "first_name": fn,
            "last_name": ln,
            "email": email,
            "hire_date": str(h_date),
            "department_id": dept_id,
            "job_id": job["job_id"],
            "manager_id": mgr_id,
            "employment_status": status,
            "employment_type": "Full-Time" if i % 10 != 0 else "Part-Time",
            "work_location": locations[i % len(locations)],
            "education_level": educations[i % len(educations)],
            "gender": genders[i % len(genders)],
            "ethnicity": ethnicities[i % len(ethnicities)]
        })
    insert_rows("employees", employees_data, token)

    # 4. Generate Compensation Records (75 rows)
    comp_reasons = ["New Hire", "Annual Merit", "Promotion", "Market Adjustment"]
    comp_data = []
    for i in range(1, 76):
        emp = employees_data[i - 1]
        job = next(j for j in jobs_data if j["job_id"] == emp["job_id"])
        min_s = float(job["min_salary"])
        max_s = float(job["max_salary"])
        salary = round(min_s + (max_s - min_s) * ((i % 10) / 10.0), 2)
        bonus = round(salary * (float(job["target_bonus_pct"]) / 100.0), 2)
        equity = round(salary * 0.25 * ((i % 5) + 1), 2)
        eff_date = date.fromisoformat(emp["hire_date"]) + timedelta(days=365)
        if eff_date > date(2026, 1, 1):
            eff_date = date(2025, 4, 1)

        comp_data.append({
            "compensation_id": f"COMP-{5000 + i}",
            "employee_id": emp["employee_id"],
            "effective_date": str(eff_date),
            "base_salary": str(salary),
            "bonus_target_amount": str(bonus),
            "equity_grant_usd": str(equity),
            "currency": "USD",
            "change_reason": comp_reasons[i % len(comp_reasons)]
        })
    insert_rows("compensation", comp_data, token)

    # 5. Generate Performance Reviews (75 rows)
    perf_data = []
    cycles = ["2024-H2", "2025-H1", "2025-H2"]
    for i in range(1, 76):
        emp = employees_data[i - 1]
        cycle = cycles[i % len(cycles)]
        rev_date = date(2025, 6, 15) if "H1" in cycle else date(2025, 12, 15)
        rating = round(3.0 + ((i % 5) * 0.45), 2)
        if rating > 5.0:
            rating = 5.0
        lead_score = round(3.2 + ((i % 4) * 0.4), 2)
        tech_score = round(3.5 + ((i % 3) * 0.5), 2)
        goal_pct = 75 + (i % 25)
        promo = (rating >= 4.5 and goal_pct >= 90)

        feedback_list = [
            "Demonstrated exceptional technical leadership and drove cross-functional initiative.",
            "Consistently delivers high impact work ahead of schedule with exemplary quality.",
            "Strong team player who actively mentors junior team members and shares best practices.",
            "Solid core execution with clear roadmap goals achieved; continue building strategic vision.",
            "Proactively solves operational bottlenecks and aligns execution with executive priorities."
        ]

        perf_data.append({
            "review_id": f"REV-{8000 + i}",
            "employee_id": emp["employee_id"],
            "review_cycle": cycle,
            "review_date": str(rev_date),
            "overall_rating": str(rating),
            "leadership_score": str(lead_score),
            "technical_score": str(tech_score),
            "goal_completion_pct": str(goal_pct),
            "promotion_recommendation": promo,
            "manager_feedback_summary": feedback_list[i % len(feedback_list)]
        })
    insert_rows("performance_reviews", perf_data, token)

    # 6. Generate Attrition / Exits (52 rows)
    exit_reasons = ["Better Compensation", "Career Opportunity", "Relocation", "Work-Life Balance", "Leadership Alignment", "Pursuing Higher Education"]
    attr_data = []
    # Take terminated employees plus simulated prior year exits for rich statistical power
    for i in range(1, 53):
        # Link to actual employee IDs or consistent past employee IDs
        emp_ref_id = employees_data[(i - 1) % len(employees_data)]["employee_id"]
        exit_d = date(2023, 1, 10) + timedelta(days=i * 22)
        tenure = round(1.2 + (i % 6) * 0.9, 1)
        exit_t = "Involuntary" if i % 6 == 0 else "Voluntary"
        reason = exit_reasons[i % len(exit_reasons)]
        rehire = (exit_t == "Voluntary" and i % 5 != 0)
        regrettable = (exit_t == "Voluntary" and tenure >= 2.0 and i % 3 != 0)

        attr_data.append({
            "exit_id": f"EXIT-{3000 + i}",
            "employee_id": emp_ref_id,
            "exit_date": str(exit_d),
            "exit_type": exit_t,
            "primary_exit_reason": reason,
            "tenure_years": str(tenure),
            "eligible_for_rehire": rehire,
            "regrettable_attrition": regrettable
        })
    insert_rows("attrition_exits", attr_data, token)

    # 7. Generate Training & Development (75 rows)
    courses = [
        ("C-101", "Executive Leadership & Strategic Influence", "Leadership"),
        ("C-102", "Cloud Architecture & Scalable Systems", "Cloud & AI Architecture"),
        ("C-103", "Generative AI Engineering & LLM Prompting", "Cloud & AI Architecture"),
        ("C-104", "Data Analytics with Looker & BigQuery", "Data Analytics"),
        ("C-105", "Global Data Privacy & HIPAA/GDPR Compliance", "Security & Compliance"),
        ("C-106", "Inclusive Leadership & Psychological Safety", "Leadership")
    ]
    train_data = []
    for i in range(1, 76):
        emp_ref = employees_data[(i - 1) % len(employees_data)]["employee_id"]
        crs = courses[i % len(courses)]
        c_date = date(2025, 1, 15) + timedelta(days=i * 5)
        status = "Completed" if i % 8 != 0 else ("In Progress" if i % 2 == 0 else "Overdue")
        score = 80 + (i % 20) if status == "Completed" else None

        train_data.append({
            "training_id": f"TRN-{9000 + i}",
            "employee_id": emp_ref,
            "course_id": crs[0],
            "course_name": crs[1],
            "category": crs[2],
            "completion_date": str(c_date) if status == "Completed" else None,
            "completion_status": status,
            "score_pct": str(score) if score else None,
            "credits_earned": 3 if status == "Completed" else 0
        })
    insert_rows("training_programs", train_data, token)

    print("\n All BigQuery tables created and populated with >= 50 rows each!")

if __name__ == "__main__":
    main()


connection: "bigquery_people_ops"

include: "/views/*.view.lkml"
include: "/dashboards/*.dashboard.lookml"

explore: employees {
  label: "People Operations Enterprise Hub"
  description: "Core central explore for People Operations analytics linking employees, departments, job architecture, compensation, performance, attrition, and training."

  join: departments {
    type: left_outer
    relationship: many_to_one
    sql_on: ${employees.department_id} = ${departments.department_id} ;;
  }

  join: jobs {
    type: left_outer
    relationship: many_to_one
    sql_on: ${employees.job_id} = ${jobs.job_id} ;;
  }

  join: compensation {
    type: left_outer
    relationship: one_to_one
    sql_on: ${employees.employee_id} = ${compensation.employee_id} ;;
  }

  join: performance_reviews {
    type: left_outer
    relationship: one_to_many
    sql_on: ${employees.employee_id} = ${performance_reviews.employee_id} ;;
  }

  join: attrition_exits {
    type: left_outer
    relationship: one_to_one
    sql_on: ${employees.employee_id} = ${attrition_exits.employee_id} ;;
  }

  join: training_programs {
    type: left_outer
    relationship: one_to_many
    sql_on: ${employees.employee_id} = ${training_programs.employee_id} ;;
  }

  # =========================================================================
  # LOOKML BUSINESS METRICS (Semantic Layer for Conversational Analytics)
  # =========================================================================

  # Metric 1: Overall Attrition Rate
  measure: attrition_rate {
    label: "Workforce Attrition Rate"
    description: "Annualized percentage of employee departures relative to total employee population. Tables joined: `employees` (base) LEFT JOIN `attrition_exits` ON `employees.employee_id = attrition_exits.employee_id`."
    type: number
    value_format_name: percent_1
    sql: 1.0 * COUNT(DISTINCT ${attrition_exits.employee_id}) / NULLIF(COUNT(DISTINCT ${employees.employee_id}), 0) ;;
  }

  # Metric 2: Regrettable Attrition Rate
  measure: regrettable_attrition_rate {
    label: "Regrettable Attrition Rate"
    description: "Percentage of voluntary departures consisting of high-impact talent marked as regrettable losses. Tables joined: `employees` LEFT JOIN `attrition_exits` ON `employees.employee_id = attrition_exits.employee_id`."
    type: number
    value_format_name: percent_1
    sql: 1.0 * COUNT(DISTINCT CASE WHEN ${attrition_exits.regrettable_attrition} THEN ${attrition_exits.employee_id} END)
         / NULLIF(COUNT(DISTINCT ${attrition_exits.employee_id}), 0) ;;
  }

  # Metric 3: Gender Pay Equity Ratio
  measure: gender_pay_equity_ratio {
    label: "Gender Pay Equity Ratio (Female to Male)"
    description: "Average female base salary divided by average male base salary. 100% indicates parity. Tables joined: `employees` LEFT JOIN `compensation` ON `employees.employee_id = compensation.employee_id`."
    type: number
    value_format_name: percent_1
    sql: (AVG(CASE WHEN ${employees.gender} = 'Female' THEN ${compensation.base_salary} END))
         / NULLIF(AVG(CASE WHEN ${employees.gender} = 'Male' THEN ${compensation.base_salary} END), 0) ;;
  }

  # Metric 4: Average Compa-Ratio
  measure: average_compa_ratio {
    label: "Average Compa-Ratio"
    description: "Employee base salary compared against the midpoint of the assigned job pay band (Base / Midpoint). Benchmark is 100%. Tables joined: `employees` LEFT JOIN `compensation` ON `employees.employee_id = compensation.employee_id` LEFT JOIN `jobs` ON `employees.job_id = jobs.job_id`."
    type: average
    value_format_name: percent_1
    sql: 1.0 * ${compensation.base_salary} / NULLIF(${jobs.midpoint_salary}, 0) ;;
  }

  # Metric 5: Headcount Budget Variance
  measure: headcount_budget_variance {
    label: "Headcount Budget vs Actual Variance"
    description: "Difference between authorized department headcount budget and currently active employees. Negative values indicate open unfilled requisitions. Tables joined: `departments` (base) LEFT JOIN `employees` ON `departments.department_id = employees.department_id`."
    type: number
    value_format_name: decimal_0
    sql: ${employees.active_headcount} - ${departments.total_headcount_budget} ;;
  }

  # Metric 6: High Performer Retention Rate
  measure: high_performer_retention_rate {
    label: "High Performer Retention Rate"
    description: "Retention percentage for employees with overall performance ratings >= 4.0. Tables joined: `employees` LEFT JOIN `performance_reviews` ON `employees.employee_id = performance_reviews.employee_id` LEFT JOIN `attrition_exits` ON `employees.employee_id = attrition_exits.employee_id`."
    type: number
    value_format_name: percent_1
    sql: 1.0 - (
      COUNT(DISTINCT CASE WHEN ${performance_reviews.overall_rating} >= 4.0 AND ${attrition_exits.exit_id} IS NOT NULL THEN ${employees.employee_id} END)
      / NULLIF(COUNT(DISTINCT CASE WHEN ${performance_reviews.overall_rating} >= 4.0 THEN ${employees.employee_id} END), 0)
    ) ;;
  }

  # Metric 7: Training Completion Efficiency
  measure: training_completion_efficiency {
    label: "L&D Training Completion Rate"
    description: "Proportion of active employees who successfully completed their assigned training modules. Tables joined: `employees` LEFT JOIN `training_programs` ON `employees.employee_id = training_programs.employee_id`."
    type: number
    value_format_name: percent_1
    sql: 1.0 * COUNT(DISTINCT CASE WHEN ${training_programs.completion_status} = 'Completed' THEN ${employees.employee_id} END)
         / NULLIF(COUNT(DISTINCT ${employees.employee_id}), 0) ;;
  }

  # Metric 8: Total Annual Workforce Investment
  measure: total_workforce_investment {
    label: "Total Annualized Workforce Investment"
    description: "Sum of total direct compensation (base salary + target bonus + equity grants) across all active employees. Tables joined: `employees` LEFT JOIN `compensation` ON `employees.employee_id = compensation.employee_id`."
    type: sum
    value_format_name: usd_0
    sql: CASE WHEN ${employees.employment_status} = 'Active' THEN ${compensation.total_direct_compensation} ELSE 0 END ;;
  }
}


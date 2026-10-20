connection: "bigquery_people_ops"

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
}

# -----------------------------------------------------
# VIEW: departments
# -----------------------------------------------------
view: departments {
  sql_table_name: `people-ops-demo.people_ops.departments` ;;

  dimension: department_id {
    primary_key: yes
    type: string
    description: "Unique department code (e.g. DEPT-001)."
    sql: ${TABLE}.department_id ;;
  }

  dimension: department_name {
    type: string
    description: "Business name of the department (Engineering, Sales, etc.)."
    sql: ${TABLE}.department_name ;;
  }

  dimension: division {
    type: string
    description: "Parent business unit (Technology, Commercial, Corporate Functions)."
    sql: ${TABLE}.division ;;
  }

  dimension: cost_center {
    type: string
    description: "Finance accounting cost center."
    sql: ${TABLE}.cost_center ;;
  }

  dimension: headcount_budget {
    type: number
    description: "Annual authorized headcount target for this department."
    sql: ${TABLE}.headcount_budget ;;
  }

  dimension: location_headquarters {
    type: string
    description: "Primary corporate office where department leadership sits."
    sql: ${TABLE}.location_headquarters ;;
  }

  dimension: lead_manager_id {
    type: string
    description: "Employee ID of the VP or Director leading this department."
    sql: ${TABLE}.lead_manager_id ;;
  }

  measure: total_headcount_budget {
    type: sum
    description: "Sum of all authorized departmental headcount positions."
    sql: ${headcount_budget} ;;
  }
}

# -----------------------------------------------------
# VIEW: jobs
# -----------------------------------------------------
view: jobs {
  sql_table_name: `people-ops-demo.people_ops.jobs` ;;

  dimension: job_id {
    primary_key: yes
    type: string
    description: "Unique job profile ID (e.g. JOB-001)."
    sql: ${TABLE}.job_id ;;
  }

  dimension: job_title {
    type: string
    description: "Official title of the position."
    sql: ${TABLE}.job_title ;;
  }

  dimension: job_family {
    type: string
    description: "Functional job discipline (Software Engineering, Sales, Product, etc.)."
    sql: ${TABLE}.job_family ;;
  }

  dimension: job_level {
    type: string
    description: "Seniority grade level (L3 Junior, L4 Mid, L5 Senior, L6 Staff, M1 Manager)."
    sql: ${TABLE}.job_level ;;
  }

  dimension: department_id {
    type: string
    hidden: yes
    sql: ${TABLE}.department_id ;;
  }

  dimension: min_salary {
    type: number
    description: "Minimum approved annual base compensation in USD."
    value_format_name: usd_0
    sql: ${TABLE}.min_salary ;;
  }

  dimension: max_salary {
    type: number
    description: "Maximum approved annual base compensation in USD."
    value_format_name: usd_0
    sql: ${TABLE}.max_salary ;;
  }

  dimension: midpoint_salary {
    type: number
    description: "Market compensation midpoint for the pay band."
    value_format_name: usd_0
    sql: (${min_salary} + ${max_salary}) / 2.0 ;;
  }

  dimension: target_bonus_pct {
    type: number
    description: "Incentive bonus percentage target."
    value_format_name: percent_1
    sql: ${TABLE}.target_bonus_pct / 100.0 ;;
  }

  dimension: is_managerial {
    type: yesno
    description: "Flag indicating whether this job includes direct people manager responsibilities."
    sql: ${TABLE}.is_managerial ;;
  }

  measure: count {
    type: count
    description: "Count of job profiles."
    drill_fields: [job_id, job_title, job_family, job_level]
  }
}

# -----------------------------------------------------
# VIEW: employees
# -----------------------------------------------------
view: employees {
  sql_table_name: `people-ops-demo.people_ops.employees` ;;

  dimension: employee_id {
    primary_key: yes
    type: string
    description: "Unique employee identifier (e.g. EMP-1001)."
    sql: ${TABLE}.employee_id ;;
  }

  dimension: first_name {
    type: string
    description: "Legal first name of the employee."
    sql: ${TABLE}.first_name ;;
  }

  dimension: last_name {
    type: string
    description: "Legal last name of the employee."
    sql: ${TABLE}.last_name ;;
  }

  dimension: full_name {
    type: string
    description: "Combined full name of the employee."
    sql: CONCAT(${first_name}, ' ', ${last_name}) ;;
  }

  dimension: email {
    type: string
    description: "Corporate email address."
    sql: ${TABLE}.email ;;
  }

  dimension_group: hire {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    description: "Date the employee joined the company."
    sql: ${TABLE}.hire_date ;;
  }

  dimension: department_id {
    type: string
    hidden: yes
    description: "Foreign key referencing departments.department_id."
    sql: ${TABLE}.department_id ;;
  }

  dimension: job_id {
    type: string
    hidden: yes
    description: "Foreign key referencing jobs.job_id."
    sql: ${TABLE}.job_id ;;
  }

  dimension: manager_id {
    type: string
    description: "Employee ID of direct reporting manager."
    sql: ${TABLE}.manager_id ;;
  }

  dimension: employment_status {
    type: string
    description: "Current employment status: Active, Terminated, On Leave."
    sql: ${TABLE}.employment_status ;;
  }

  dimension: is_active {
    type: yesno
    description: "Whether the employee is currently actively employed."
    sql: ${TABLE}.employment_status = 'Active' ;;
  }

  dimension: employment_type {
    type: string
    description: "Full-Time, Part-Time, or Contract."
    sql: ${TABLE}.employment_type ;;
  }

  dimension: work_location {
    type: string
    description: "Physical assigned office site or Remote."
    sql: ${TABLE}.work_location ;;
  }

  dimension: education_level {
    type: string
    description: "Highest completed education credential (Bachelors, Masters, PhD)."
    sql: ${TABLE}.education_level ;;
  }

  dimension: gender {
    type: string
    description: "Self-identified gender demographic attribute."
    sql: ${TABLE}.gender ;;
  }

  dimension: ethnicity {
    type: string
    description: "Self-identified race / ethnicity demographic attribute."
    sql: ${TABLE}.ethnicity ;;
  }

  # --- Standard Measures ---

  measure: count {
    type: count
    description: "Total count of employee records."
    drill_fields: [employee_id, full_name, email, employment_status, work_location]
  }

  measure: active_headcount {
    type: count
    description: "Current count of active employees."
    filters: [employment_status: "Active"]
    drill_fields: [employee_id, full_name, email, work_location]
  }

  # =========================================================================
  # LOOKML BUSINESS METRICS (Semantic Layer for Conversational Analytics)
  # =========================================================================

  # Metric 1: Overall Attrition Rate
  measure: attrition_rate {
    label: "Workforce Attrition Rate"
    description: "Annualized percentage of employee departures relative to total employee population. Tables joined: employees (base) LEFT JOIN attrition_exits ON employees.employee_id = attrition_exits.employee_id."
    type: number
    value_format_name: percent_1
    sql: 1.0 * COUNT(DISTINCT ${attrition_exits.employee_id}) / NULLIF(COUNT(DISTINCT ${employees.employee_id}), 0) ;;
  }

  # Metric 2: Regrettable Attrition Rate
  measure: regrettable_attrition_rate {
    label: "Regrettable Attrition Rate"
    description: "Percentage of voluntary departures consisting of high-impact talent marked as regrettable losses. Tables joined: employees LEFT JOIN attrition_exits ON employees.employee_id = attrition_exits.employee_id."
    type: number
    value_format_name: percent_1
    sql: 1.0 * COUNT(DISTINCT CASE WHEN ${attrition_exits.regrettable_attrition} THEN ${attrition_exits.employee_id} END)
         / NULLIF(COUNT(DISTINCT ${attrition_exits.employee_id}), 0) ;;
  }

  # Metric 3: Gender Pay Equity Ratio
  measure: gender_pay_equity_ratio {
    label: "Gender Pay Equity Ratio (Female to Male)"
    description: "Average female base salary divided by average male base salary. 100% indicates parity. Tables joined: employees LEFT JOIN compensation ON employees.employee_id = compensation.employee_id."
    type: number
    value_format_name: percent_1
    sql: (AVG(CASE WHEN ${employees.gender} = 'Female' THEN ${compensation.base_salary} END))
         / NULLIF(AVG(CASE WHEN ${employees.gender} = 'Male' THEN ${compensation.base_salary} END), 0) ;;
  }

  # Metric 4: Average Compa-Ratio
  measure: average_compa_ratio {
    label: "Average Compa-Ratio"
    description: "Employee base salary compared against the midpoint of the assigned job pay band (Base / Midpoint). Benchmark is 100%. Tables joined: employees LEFT JOIN compensation ON employees.employee_id = compensation.employee_id LEFT JOIN jobs ON employees.job_id = jobs.job_id."
    type: average
    value_format_name: percent_1
    sql: 1.0 * ${compensation.base_salary} / NULLIF(${jobs.midpoint_salary}, 0) ;;
  }

  # Metric 5: Headcount Budget Variance
  measure: headcount_budget_variance {
    label: "Headcount Budget vs Actual Variance"
    description: "Difference between authorized department headcount budget and currently active employees. Tables joined: departments (base) LEFT JOIN employees ON departments.department_id = employees.department_id."
    type: number
    value_format_name: decimal_0
    sql: ${active_headcount} - ${departments.total_headcount_budget} ;;
  }

  # Metric 6: High Performer Retention Rate
  measure: high_performer_retention_rate {
    label: "High Performer Retention Rate"
    description: "Retention percentage for employees with overall performance ratings >= 4.0. Tables joined: employees LEFT JOIN performance_reviews ON employees.employee_id = performance_reviews.employee_id LEFT JOIN attrition_exits ON employees.employee_id = attrition_exits.employee_id."
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
    description: "Proportion of active employees who successfully completed their assigned training modules. Tables joined: employees LEFT JOIN training_programs ON employees.employee_id = training_programs.employee_id."
    type: number
    value_format_name: percent_1
    sql: 1.0 * COUNT(DISTINCT CASE WHEN ${training_programs.completion_status} = 'Completed' THEN ${employees.employee_id} END)
         / NULLIF(COUNT(DISTINCT ${employees.employee_id}), 0) ;;
  }

  # Metric 8: Total Annual Workforce Investment
  measure: total_workforce_investment {
    label: "Total Annualized Workforce Investment"
    description: "Sum of total direct compensation (base salary + target bonus + equity grants) across all active employees. Tables joined: employees LEFT JOIN compensation ON employees.employee_id = compensation.employee_id."
    type: sum
    value_format_name: usd_0
    sql: CASE WHEN ${employees.employment_status} = 'Active' THEN ${compensation.total_direct_compensation} ELSE 0 END ;;
  }
}

# -----------------------------------------------------
# VIEW: compensation
# -----------------------------------------------------
view: compensation {
  sql_table_name: `people-ops-demo.people_ops.compensation` ;;

  dimension: compensation_id {
    primary_key: yes
    type: string
    description: "Unique compensation record ID."
    sql: ${TABLE}.compensation_id ;;
  }

  dimension: employee_id {
    type: string
    hidden: yes
    sql: ${TABLE}.employee_id ;;
  }

  dimension_group: effective {
    type: time
    timeframes: [raw, date, month, quarter, year]
    convert_tz: no
    datatype: date
    description: "Date when this salary and compensation package became effective."
    sql: ${TABLE}.effective_date ;;
  }

  dimension: base_salary {
    type: number
    description: "Annual base salary amount in USD."
    value_format_name: usd_0
    sql: ${TABLE}.base_salary ;;
  }

  dimension: bonus_target_amount {
    type: number
    description: "Target annual performance bonus amount in USD."
    value_format_name: usd_0
    sql: ${TABLE}.bonus_target_amount ;;
  }

  dimension: equity_grant_usd {
    type: number
    description: "Value of equity RSUs granted annually in USD."
    value_format_name: usd_0
    sql: ${TABLE}.equity_grant_usd ;;
  }

  dimension: total_target_cash {
    type: number
    description: "Total annual cash target compensation (base salary + target bonus)."
    value_format_name: usd_0
    sql: ${base_salary} + COALESCE(${bonus_target_amount}, 0) ;;
  }

  dimension: total_direct_compensation {
    type: number
    description: "Total annual target direct compensation (base salary + bonus + equity)."
    value_format_name: usd_0
    sql: ${base_salary} + COALESCE(${bonus_target_amount}, 0) + COALESCE(${equity_grant_usd}, 0) ;;
  }

  dimension: change_reason {
    type: string
    description: "Trigger reason for salary event: New Hire, Annual Merit, Promotion, Market Adjustment."
    sql: ${TABLE}.change_reason ;;
  }

  measure: total_base_payroll {
    type: sum
    description: "Total sum of annual base salary across employee population."
    value_format: "$#,##0.0,,\"M\""
    sql: ${base_salary} ;;
  }

  measure: average_base_salary {
    type: average
    description: "Mean annual base salary across selected employees."
    value_format_name: usd_0
    sql: ${base_salary} ;;
  }

  measure: median_base_salary {
    type: median
    description: "Median base salary across employees."
    value_format_name: usd_0
    sql: ${base_salary} ;;
  }

  measure: total_equity_value {
    type: sum
    description: "Total annual equity RSU grant value in USD."
    value_format_name: usd_0
    sql: ${equity_grant_usd} ;;
  }
}

# -----------------------------------------------------
# VIEW: performance_reviews
# -----------------------------------------------------
view: performance_reviews {
  sql_table_name: `people-ops-demo.people_ops.performance_reviews` ;;

  dimension: review_id {
    primary_key: yes
    type: string
    description: "Unique performance evaluation review ID."
    sql: ${TABLE}.review_id ;;
  }

  dimension: employee_id {
    type: string
    hidden: yes
    sql: ${TABLE}.employee_id ;;
  }

  dimension: review_cycle {
    type: string
    description: "Evaluation cycle name (e.g. 2024-H2, 2025-H1)."
    sql: ${TABLE}.review_cycle ;;
  }

  dimension_group: review {
    type: time
    timeframes: [raw, date, month, quarter, year]
    convert_tz: no
    datatype: date
    description: "Date the performance review was conducted and finalized."
    sql: ${TABLE}.review_date ;;
  }

  dimension: overall_rating {
    type: number
    description: "Calibrated overall performance rating score (1.0 to 5.0)."
    value_format_name: decimal_2
    sql: ${TABLE}.overall_rating ;;
  }

  dimension: performance_bracket {
    type: string
    description: "Categorical tier based on performance rating."
    sql: CASE
           WHEN ${overall_rating} >= 4.5 THEN 'Top Performer (4.5 - 5.0)'
           WHEN ${overall_rating} >= 3.5 THEN 'Solid Performer (3.5 - 4.4)'
           WHEN ${overall_rating} >= 2.5 THEN 'Developing (2.5 - 3.4)'
           ELSE 'Needs Improvement (< 2.5)'
         END ;;
  }

  dimension: leadership_score {
    type: number
    description: "Leadership competency score (1.0 to 5.0)."
    value_format_name: decimal_2
    sql: ${TABLE}.leadership_score ;;
  }

  dimension: technical_score {
    type: number
    description: "Technical mastery and execution score (1.0 to 5.0)."
    value_format_name: decimal_2
    sql: ${TABLE}.technical_score ;;
  }

  dimension: goal_completion_pct {
    type: number
    description: "Percentage of OKRs / performance goals achieved."
    value_format_name: percent_1
    sql: ${TABLE}.goal_completion_pct / 100.0 ;;
  }

  dimension: promotion_recommendation {
    type: yesno
    description: "Whether manager recommended employee for promotion."
    sql: ${TABLE}.promotion_recommendation ;;
  }

  dimension: manager_feedback_summary {
    type: string
    description: "Qualitative narrative summary written by reviewing manager."
    sql: ${TABLE}.manager_feedback_summary ;;
  }

  measure: average_performance_rating {
    type: average
    description: "Average calibrated performance rating across employee population."
    value_format_name: decimal_2
    sql: ${overall_rating} ;;
  }

  measure: promotion_nomination_rate {
    type: average
    description: "Share of employees nominated for promotion in the cycle."
    value_format_name: percent_1
    sql: CASE WHEN ${promotion_recommendation} THEN 1.0 ELSE 0.0 END ;;
  }

  measure: average_goal_completion_pct {
    type: average
    description: "Average OKR milestone completion percentage."
    value_format_name: percent_1
    sql: ${goal_completion_pct} ;;
  }
}

# -----------------------------------------------------
# VIEW: attrition_exits
# -----------------------------------------------------
view: attrition_exits {
  sql_table_name: `people-ops-demo.people_ops.attrition_exits` ;;

  dimension: exit_id {
    primary_key: yes
    type: string
    description: "Unique employee departure exit identifier."
    sql: ${TABLE}.exit_id ;;
  }

  dimension: employee_id {
    type: string
    hidden: yes
    sql: ${TABLE}.employee_id ;;
  }

  dimension_group: exit {
    type: time
    timeframes: [raw, date, month, quarter, year]
    convert_tz: no
    datatype: date
    description: "Official termination/departure date."
    sql: ${TABLE}.exit_date ;;
  }

  dimension: exit_type {
    type: string
    description: "Separation type: Voluntary (resignation) vs Involuntary (layoff/termination)."
    sql: ${TABLE}.exit_type ;;
  }

  dimension: is_voluntary {
    type: yesno
    description: "Whether separation was voluntary resignation."
    sql: ${TABLE}.exit_type = 'Voluntary' ;;
  }

  dimension: primary_exit_reason {
    type: string
    description: "Primary driver behind departure (Compensation, Career Opportunity, etc.)."
    sql: ${TABLE}.primary_exit_reason ;;
  }

  dimension: tenure_years {
    type: number
    description: "Total tenure in years at time of departure."
    value_format_name: decimal_1
    sql: ${TABLE}.tenure_years ;;
  }

  dimension: eligible_for_rehire {
    type: yesno
    description: "Whether employee is eligible to be rehired in the future."
    sql: ${TABLE}.eligible_for_rehire ;;
  }

  dimension: regrettable_attrition {
    type: yesno
    description: "Whether the exit represents a critical top-performer loss."
    sql: ${TABLE}.regrettable_attrition ;;
  }

  measure: total_exits {
    type: count
    description: "Total count of employee separations."
    drill_fields: [exit_id, exit_date, exit_type, primary_exit_reason, tenure_years]
  }

  measure: voluntary_exits {
    type: count
    description: "Count of voluntary employee resignations."
    filters: [exit_type: "Voluntary"]
  }

  measure: involuntary_exits {
    type: count
    description: "Count of involuntary employee terminations."
    filters: [exit_type: "Involuntary"]
  }

  measure: regrettable_exits {
    type: count
    description: "Count of regrettable high-performer departures."
    filters: [regrettable_attrition: "yes"]
  }

  measure: average_tenure_at_exit {
    type: average
    description: "Average years of service before exit."
    value_format_name: decimal_1
    sql: ${tenure_years} ;;
  }
}

# -----------------------------------------------------
# VIEW: training_programs
# -----------------------------------------------------
view: training_programs {
  sql_table_name: `people-ops-demo.people_ops.training_programs` ;;

  dimension: training_id {
    primary_key: yes
    type: string
    description: "Unique training enrollment ID."
    sql: ${TABLE}.training_id ;;
  }

  dimension: employee_id {
    type: string
    hidden: yes
    sql: ${TABLE}.employee_id ;;
  }

  dimension: course_id {
    type: string
    description: "Catalog code for course."
    sql: ${TABLE}.course_id ;;
  }

  dimension: course_name {
    type: string
    description: "Title of training course or certification program."
    sql: ${TABLE}.course_name ;;
  }

  dimension: category {
    type: string
    description: "Course discipline: Leadership, Cloud & AI Architecture, Data Analytics, Security & Compliance."
    sql: ${TABLE}.category ;;
  }

  dimension_group: completion {
    type: time
    timeframes: [raw, date, month, quarter, year]
    convert_tz: no
    datatype: date
    description: "Date of course completion."
    sql: ${TABLE}.completion_date ;;
  }

  dimension: completion_status {
    type: string
    description: "Status: Completed, In Progress, Overdue."
    sql: ${TABLE}.completion_status ;;
  }

  dimension: is_completed {
    type: yesno
    description: "Whether the course has been completed."
    sql: ${TABLE}.completion_status = 'Completed' ;;
  }

  dimension: score_pct {
    type: number
    description: "Exam / assessment percentage score."
    value_format_name: percent_1
    sql: ${TABLE}.score_pct / 100.0 ;;
  }

  dimension: credits_earned {
    type: number
    description: "Continuing education credits earned."
    sql: ${TABLE}.credits_earned ;;
  }

  measure: total_enrollments {
    type: count
    description: "Total course registrations."
  }

  measure: completed_courses {
    type: count
    description: "Total number of courses completed."
    filters: [completion_status: "Completed"]
  }

  measure: completion_rate {
    type: number
    description: "Percentage of training enrollments successfully completed."
    value_format_name: percent_1
    sql: 1.0 * ${completed_courses} / NULLIF(${total_enrollments}, 0) ;;
  }

  measure: average_exam_score {
    type: average
    description: "Average exam score on completed courses."
    value_format_name: percent_1
    sql: ${score_pct} ;;
  }
}

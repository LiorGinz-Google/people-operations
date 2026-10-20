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


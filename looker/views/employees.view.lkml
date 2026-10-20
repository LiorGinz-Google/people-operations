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
}


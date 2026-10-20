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


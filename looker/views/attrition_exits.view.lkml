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


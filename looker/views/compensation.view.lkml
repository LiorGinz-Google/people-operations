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


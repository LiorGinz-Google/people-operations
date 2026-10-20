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


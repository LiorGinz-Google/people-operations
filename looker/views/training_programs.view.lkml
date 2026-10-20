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


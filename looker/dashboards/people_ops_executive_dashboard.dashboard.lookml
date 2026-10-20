- dashboard: people_operations_executive_overview
  title: "People Operations & Human Capital Executive Dashboard"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Executive enterprise analytics dashboard providing strategic insights into headcount growth, compensation benchmarking, diversity & pay equity, attrition drivers, and workforce performance."

  filters:
    - name: division
      title: "Division"
      type: field_filter
      default_value: ""
      allow_multiple_values: true
      required: false
      model: people_ops
      explore: employees
      listens_to_filters: []
      field: departments.division

    - name: work_location
      title: "Work Location"
      type: field_filter
      default_value: ""
      allow_multiple_values: true
      required: false
      model: people_ops
      explore: employees
      listens_to_filters: []
      field: employees.work_location

  elements:
    # Row 1: KPI Single Values (Width 4 each)
    - name: kpi_active_headcount
      title: "Active Headcount"
      model: people_ops
      explore: employees
      type: single_value
      fields: [employees.active_headcount]
      custom_color_enabled: true
      show_single_value_title: true
      show_comparison: false
      comparison_type: value
      comparison_reverse_colors: false
      show_comparison_label: true
      note_state: collapsed
      note_display: hover
      note_text: "Current actively employed full-time & part-time workforce."
      row: 0
      col: 0
      width: 4
      height: 3

    - name: kpi_total_payroll
      title: "Annual Base Payroll"
      model: people_ops
      explore: employees
      type: single_value
      fields: [compensation.total_base_payroll]
      custom_color_enabled: true
      show_single_value_title: true
      show_comparison: false
      note_state: collapsed
      note_display: hover
      note_text: "Total annual base salary commitment for active employees."
      row: 0
      col: 4
      width: 4
      height: 3

    - name: kpi_attrition_rate
      title: "Attrition Rate"
      model: people_ops
      explore: employees
      type: single_value
      fields: [employees.attrition_rate]
      custom_color_enabled: true
      show_single_value_title: true
      show_comparison: false
      note_state: collapsed
      note_display: hover
      note_text: "Separations relative to total employee population."
      row: 0
      col: 8
      width: 4
      height: 3

    - name: kpi_regrettable_rate
      title: "Regrettable Attrition"
      model: people_ops
      explore: employees
      type: single_value
      fields: [employees.regrettable_attrition_rate]
      custom_color_enabled: true
      show_single_value_title: true
      show_comparison: false
      note_state: collapsed
      note_display: hover
      note_text: "Percentage of voluntary departures classified as critical top-performer losses."
      row: 0
      col: 12
      width: 4
      height: 3

    - name: kpi_compa_ratio
      title: "Avg Compa-Ratio"
      model: people_ops
      explore: employees
      type: single_value
      fields: [employees.average_compa_ratio]
      custom_color_enabled: true
      show_single_value_title: true
      show_comparison: false
      note_state: collapsed
      note_display: hover
      note_text: "Market competitiveness index. 100% indicates exact alignment with salary midpoint."
      row: 0
      col: 16
      width: 4
      height: 3

    - name: kpi_avg_performance
      title: "Avg Rating"
      model: people_ops
      explore: employees
      type: single_value
      fields: [performance_reviews.average_performance_rating]
      custom_color_enabled: true
      show_single_value_title: true
      show_comparison: false
      note_state: collapsed
      note_display: hover
      note_text: "Mean calibrated employee performance score on a 1.0 - 5.0 scale."
      row: 0
      col: 20
      width: 4
      height: 3

    # Row 2: Charts
    - name: headcount_by_dept
      title: "Headcount & Department Allocation"
      model: people_ops
      explore: employees
      type: looker_bar
      fields: [departments.department_name, employees.active_headcount, departments.total_headcount_budget]
      sorts: [employees.active_headcount desc]
      limit: 10
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      show_y_axis_labels: true
      show_y_axis_ticks: true
      y_axis_tick_density: default
      show_x_axis_label: false
      show_x_axis_ticks: true
      legend_position: bottom
      series_labels:
        employees.active_headcount: "Active Headcount"
        departments.total_headcount_budget: "Budget"
      series_types: {}
      series_colors:
        employees.active_headcount: "#1A73E8"
        departments.total_headcount_budget: "#AECBFA"
      row: 3
      col: 0
      width: 12
      height: 9

    - name: compensation_by_job_level_gender
      title: "Base Salary Equity by Career Level & Gender"
      model: people_ops
      explore: employees
      type: looker_column
      fields: [jobs.job_level, employees.gender, compensation.average_base_salary]
      pivots: [employees.gender]
      sorts: [jobs.job_level asc, employees.gender asc]
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      show_y_axis_labels: true
      y_axis_labels: ["Avg Base Salary ($)"]
      show_y_axis_ticks: true
      y_axis_tick_density: default
      show_x_axis_label: true
      x_axis_label: "Career Level"
      show_x_axis_ticks: true
      legend_position: bottom
      series_colors:
        Female - compensation.average_base_salary: "#E8710A"
        Male - compensation.average_base_salary: "#1A73E8"
        Non-Binary - compensation.average_base_salary: "#12B5CB"
      row: 3
      col: 12
      width: 12
      height: 9
      legend_position: top
      series_colors:
        Female - compensation.average_base_salary: "#E8710A"
        Male - compensation.average_base_salary: "#1A73E8"
        Non-Binary - compensation.average_base_salary: "#12B5CB"
      row: 3
      col: 12
      width: 12
      height: 8

    # Row 3: Attrition Trends and Drivers
    - name: exit_reasons_breakdown
      title: "Primary Voluntary Departure Drivers"
      model: people_ops
      explore: employees
      type: looker_pie
      fields: [attrition_exits.primary_exit_reason, attrition_exits.total_exits]
      filters:
        attrition_exits.exit_type: "Voluntary"
      sorts: [attrition_exits.total_exits desc]
      inner_radius: 55
      series_colors:
        Better Compensation: "#EA4335"
        Career Opportunity: "#FBBC04"
        Relocation: "#4285F4"
        Work-Life Balance: "#34A853"
        Leadership Alignment: "#A142F4"
      row: 12
      col: 0
      width: 8
      height: 8

    - name: performance_vs_compensation
      title: "Performance Rating vs Base Salary Distribution"
      model: people_ops
      explore: employees
      type: looker_scatter
      fields: [performance_reviews.overall_rating, compensation.base_salary, employees.full_name, jobs.job_title]
      sorts: [performance_reviews.overall_rating desc]
      x_axis_gridlines: true
      y_axis_gridlines: true
      show_view_names: false
      show_y_axis_labels: true
      show_x_axis_label: true
      x_axis_label: "Performance Rating (1.0 to 5.0)"
      y_axis_label: "Base Salary ($ USD)"
      series_colors:
        compensation.base_salary: "#34A853"
      row: 12
      col: 8
      width: 8
      height: 8

    - name: training_track_efficiency
      title: "L&D Program Completion by Category"
      model: people_ops
      explore: employees
      type: looker_column
      fields: [training_programs.category, training_programs.completed_courses, training_programs.total_enrollments, training_programs.average_exam_score]
      sorts: [training_programs.total_enrollments desc]
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      show_y_axis_labels: true
      show_x_axis_label: false
      legend_position: bottom
      series_types:
        training_programs.average_exam_score: line
      series_colors:
        training_programs.completed_courses: "#188038"
        training_programs.total_enrollments: "#CEEAD6"
        training_programs.average_exam_score: "#EA4335"
      row: 12
      col: 16
      width: 8
      height: 8

    # Row 4: High Performer Talent Review Table
    - name: top_performer_talent_table
      title: "Top Performer Calibration & Retention Watchlist"
      model: people_ops
      explore: employees
      type: looker_grid
      fields: [employees.employee_id, employees.full_name, departments.department_name, jobs.job_title, performance_reviews.overall_rating, performance_reviews.promotion_recommendation, compensation.base_salary, employees.average_compa_ratio]
      filters:
        performance_reviews.overall_rating: ">=4.0"
        employees.employment_status: "Active"
      sorts: [performance_reviews.overall_rating desc]
      show_view_names: false
      show_row_numbers: true
      transpose: false
      truncate_text: true
      hide_totals: false
      hide_row_totals: false
      size_to_fit: true
      table_theme: white
      limit_displayed_rows: false
      enable_conditional_formatting: true
      conditional_formatting: [{
        type: along a scale...,
        value: null,
        background_color: "#1A73E8",
        font_color: null,
        color_application: {
          collection_id: 7c5612da-06ff-4408-b49d-3402e1e427a4,
          custom: {
            id: 28bb7c04-f3c5-9aa4-d2e3-2f2f70356784,
            label: Custom,
            type: continuous,
            stops: [{color: "#E8F0FE", offset: 0}, {color: "#188038", offset: 100}]
          }
        },
        bold: false,
        italic: false,
        strikethrough: false,
        fields: [performance_reviews.overall_rating]
      }]
      row: 20
      col: 0
      width: 24
      height: 7


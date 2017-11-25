class EasyGanttEasyIssueQuery < EasyIssueQuery

  KEEP_AVAILABLE_COLUMNS = [
    # Issues
    :id, :project, :parent, :status, :tracker, :priority, :fixed_version, :subject, :start_date, :due_date, :created_on, :updated_on, :easy_status_updated_on, :open_duration_in_hours, :easy_last_updated_by, :done_ratio, :easy_due_date_time_remaining, :closed_on, :easy_closed_by, :is_private, :category, :assigned_to, :author, :estimated_hours, :total_estimated_hours, :spent_hours, :total_spent_hours, :remaining_timeentries, :total_remaining_timeentries, :spent_estimated_timeentries, :total_spent_estimated_timeentries,

    # Projects
   :"projects.name", :"projects.parent", :"projects.root", :"projects.status", :"projects.start_date", :"projects.due_date", :"projects.created_on", :"projects.updated_on", :"projects.easy_indicator", :"projects.identifier", :"projects.completed_percent", :"projects.priority", :"projects.sum_estimated_hours", :"projects.total_sum_estimated_hours", :"projects.sum_of_timeentries", :"projects.remaining_timeentries", :"projects.total_remaining_timeentries", :"projects.total_spent_hours", :"projects.author"
  ]

  attr_accessor :opened_project

  def query_after_initialize
    super

    self.display_filter_group_by_on_index = false
    self.display_filter_sort_on_index = false
    self.display_filter_settings_on_index = false

    self.display_filter_group_by_on_edit = false
    self.display_filter_sort_on_edit = false
    self.display_filter_settings_on_edit = false

    self.display_show_sum_row = false
    self.display_load_groups_opened = false

    self.export_formats = {}
    self.is_tagged = true if new_record?
  end

  def available_outputs
    []
  end

  def groupable_columns
    []
  end

  def available_outputs
    ['list']
  end

  def default_list_columns
    super.presence || ['subject', 'assigned_to']
  end

  def easy_query_entity_controller
    'easy_gantt'
  end

  def easy_query_entity_action
    'index'
  end

  def column_groups_ordering
    [
      l(:label_most_used),
      l("label_filter_group_#{class_name_underscored}"),
      EasyQuery.column_filter_group_name(nil),
      l(:label_filter_group_easy_time_entry_query),
      l(:label_filter_group_status_time),
      l(:label_filter_group_status_count),
      l(:label_filter_group_easy_project_query),
      EasyQuery.column_filter_group_name(:project),
      l(:label_user_plural)
    ]
  end

  def entity_easy_query_path(**options)
    project = options[:project] || project
    if project
      easy_gantt_path(project, options)
    end
  end

  # Delete these filters because of project_scope
  def initialize_available_filters
    super
    @available_filters.delete('subproject_id')
  end

  def initialize_available_columns
    super
    add_associated_columns EasyProjectQuery

    @available_columns.keep_if { |column|
      KEEP_AVAILABLE_COLUMNS.include?(column.name) ||
      column.name.to_s.start_with?('cf_') ||
      column.name.to_s.start_with?('projects.cf_')
    }
  end

  def project_scope
    # Except closed and archived
    scope = Project.active_and_planned

    # Templates should be included only on template context
    if project.nil? || !project.easy_is_easy_template?
      scope = scope.non_templates
    end

    if opened_project
      scope = scope.where(id: opened_project.id)
    end

    if has_filter?('is_planned')
      op = value_for('is_planned') == '1' ? '=' : '<>'
      scope = scope.where("#{Project.table_name}.status #{op} ?", Project::STATUS_PLANNED)
    end

    scope
  end

  def without_opened_project
    _opened_project = opened_project
    self.opened_project = nil
    self.additional_scope = nil
    yield self
  ensure
    self.opened_project = _opened_project
    self.additional_scope = nil
  end

  def self.chart_support?
    false
  end

end

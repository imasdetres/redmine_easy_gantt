class EasyGanttEasyProjectQuery < EasyProjectQuery

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

  def groupable_columns
    []
  end

  def available_outputs
    ['list']
  end

  def default_list_columns
    super.presence || ['name']
  end

  def filter_groups_ordering
    [
      l(:label_most_used),
      l(:label_filter_group_easy_project_query),
      EasyQuery.column_filter_group_name(nil)
    ]
  end

  def column_groups_ordering
    [
      l(:label_most_used),
      l(:label_filter_group_easy_project_query),
      EasyQuery.column_filter_group_name(nil),
      l(:label_filter_group_easy_time_entry_query),
      l(:label_user_plural)
    ]
  end

  def easy_query_entity_controller
    'easy_gantt'
  end

  def easy_query_entity_action
    'index'
  end

  def entity_easy_query_path(**options)
    easy_gantt_path(options)
  end

  def additional_scope
    if opened_project
      Project.where(id: opened_project.id)
    else
      nil
    end
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

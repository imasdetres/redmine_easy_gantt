module EasyGantt
  module QueriesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        if method_defined?(:query_class) || private_method_defined?(:query_class)
          alias_method_chain :query_class, :easy_gantt
        end
      end
    end

    module InstanceMethods

      # Redmine return only direct sublasses but
      # Gantt query inherit from IssueQuery
      def query_class_with_easy_gantt
        case params[:type]
        when 'EasyGantt::EasyGanttIssueQuery'
          EasyGantt::EasyGanttIssueQuery
        else
          query_class_without_easy_gantt
        end
      end

    end

  end
end

RedmineExtensions::PatchManager.register_controller_patch 'QueriesController', 'EasyGantt::QueriesControllerPatch'

module EasyGantt
  module ApplicationHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def link_to_project_with_easy_gantt(project, options = {})
          { controller: 'easy_gantt', action: 'index', project_id: project }
        end

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end
end

RedmineExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyGantt::ApplicationHelperPatch'

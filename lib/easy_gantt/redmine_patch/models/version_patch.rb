module EasyGantt
  module VersionPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
      end
    end

    module InstanceMethods

      def gantt_editable?(user=nil)
        user ||= User.current

        (user.allowed_to?(:edit_easy_gantt, project) ||
         user.allowed_to_globally?(:edit_global_easy_gantt)) &&
        user.allowed_to?(:manage_versions, project)
      end

    end

  end
end

RedmineExtensions::PatchManager.register_model_patch 'Version', 'EasyGantt::VersionPatch'

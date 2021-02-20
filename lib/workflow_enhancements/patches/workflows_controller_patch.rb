module WorkflowEnhancements
  module Patches
    module WorkflowsControllerPatch
      def self.included(base) # :nodoc
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :find_statuses , :workflow_enhancements
        end
      end

      module ClassMethods; end

      module InstanceMethods
        def find_statuses_with_workflow_enhancements
          @used_statuses_only = (params[:used_statuses_only] == '0' ? false : true)
          if @trackers && @used_statuses_only
            role_ids = Role.all.select(&:consider_workflow?).map(&:id)
            status_ids = (WorkflowTransition.where(tracker_id: @trackers.map(&:id), role_id: role_ids).
                            distinct.pluck(:old_status_id, :new_status_id) +
                          TrackerStatus.where(tracker_id: @trackers.map(&:id)).
                            distinct.pluck(:issue_status_id)).flatten.uniq
            @statuses = IssueStatus.where(id: status_ids).sorted.to_a.presence
          end
          @used_role_statuses_only = (params[:used_role_statuses_only] == '0' ? false : true)
          if @roles && @used_role_statuses_only
            role_ids = @roles.select(&:consider_workflow?).map(&:id)
            status_ids = WorkflowTransition.where(role_id: role_ids).
                           distinct.pluck(:old_status_id, :new_status_id).flatten.uniq
            @role_statuses = IssueStatus.where(id: status_ids).sorted.to_a.presence
            @statuses = (@statuses && @role_statuses & @statuses || @statuses || @role_statuses).presence
          end
          @statuses ||= IssueStatus.sorted.to_a
        end
      end
    end
  end
end

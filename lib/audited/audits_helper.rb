# frozen_string_literal: true

module Audited
  module AuditsHelper
    def humanize_audit(audit, i18n_context: {})
      downcased_type = audit.auditable_type.downcase

      changes = case audit.action
      when "create"
        t(
          "audited.#{downcased_type}.create",
          **audit.audited_changes,
          **i18n_context,
          default: "#{audit.auditable_type} #{audit.auditable_id} was created.",
        )
      when "update"
        audit.audited_changes.map do |k, v|
          if v.first.present? && v.last.present?
            t(
              "audited.#{downcased_type}.update.changed.#{k}",
              from: v.first,
              to: v.last,
              **i18n_context,
              default: "#{k} was changed from #{v.first} to #{v.last}",
            )
          elsif !v.first.present? && v.last.present?
            t(
              "audited.#{downcased_type}.update.added.#{k}",
              value: v.first,
              default: "#{k} was added #{v.last}",
            )
          else
            t(
              "audited.#{downcased_type}.update.removed.#{k}",
              value: v.last,
              **i18n_context,
              default: "#{k} #{v.last} was removed.",
            )
          end
        end
      when "destroy"
        t(
          "audited.#{downcased_type}.create",
          **audit.audited_changes,
          **i18n_context,
          default: "#{audit.auditable_type} #{audit.auditable_id} was deleted.",
        )
      end

      Array.wrap(changes)
    end
  end
end

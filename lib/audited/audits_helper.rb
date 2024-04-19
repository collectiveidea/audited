# frozen_string_literal: true

module Audited
  module AuditsHelper
    def humanize_audit(audit, skip: nil, i18n_context: {})
      downcased_type = audit.auditable_type.downcase

      audit.audited_changes.except!(*skip.map(&:to_s)) if skip.present?

      changes = case audit.action
      when "create"
        humanize_create(audit.audited_changes, downcased_type, i18n_context)
      when "update"
        humanize_update(audit.audited_changes, downcased_type, i18n_context)
      when "destroy"
        humanize_destroy(audit.audited_changes, downcased_type, i18n_context)
      end

      Array.wrap(changes)
    end

    private

    def humanize_create(audited_changes, type, i18n_context)
      t(
        "audited.#{type}.create",
        **audited_changes,
        **i18n_context,
        default: "Created.",
      )
    end

    def humanize_destroy(audited_changes, type, i18n_context)
      t(
        "audited.#{type}.destroy",
        **audited_changes,
        **i18n_context,
        default: "Deleted.",
      )
    end

    def humanize_update(audited_changes, type, i18n_context)
      array = audited_changes.map do |k, v|
        v = v.map(&:to_s)

        if v.first.present? && v.last.present?
          humanize_changed(k, v, type, i18n_context)
        elsif !v.first.present? && v.last.present?
          t(
            "audited.#{type}.update.added.#{k}",
            value: v.first,
            default: "#{k.titleize} was added #{v.last}",
          )
        else
          t(
            "audited.#{type}.update.removed.#{k}",
            value: v.last,
            **i18n_context,
            default: "#{k.titleize} #{v.last} was removed.",
          )
        end
      end

      puts array.inspect

      array.flatten
    end

    def humanize_changed(key, value, type, i18n_context)
      return humanize_changed_array(key, value, type, i18n_context) if value.first.is_a?(Array)
      return humanize_changed_hash(key, value, type, i18n_context) if value.first.is_a?(Hash)

      t(
        "audited.#{type}.update.changed.#{key}",
        from: value.first,
        to: value.last,
        **i18n_context,
        default: "#{key.titleize} was changed from #{value.first} to #{value.last}",
      )
    end

    def humanize_changed_array(key, value, type, i18n_context)
      removed = value.first - value.last
      added = value.last - value.first

      changes = []

      if added.any?
        changes << t(
          "audited.#{type}.update.changed.array.added.#{key}",
          added: added.join(", "),
          **i18n_context,
          default: "#{key.titleize} had #{added.join(", ")} added.",
        )
      end

      if removed.any?
        changes << t(
          "audited.#{type}.update.changed.array.removed.#{key}",
          removed: removed.join(", "),
          **i18n_context,
          default: "#{key.titleize} had #{removed.join(", ")} removed.",
        )
      end
    end

    def humanize_changed_hash(key, value, type, i18n_context)
      changes = {}

      value.first.each do |k, v|
        next if v == value.last[k]

        changes[k] = [ v, value.last[k] ]
      end

      value.last.each do |k, v|
        next if value.first.key?(k)

        changes[k] = [ nil, v ]
      end

      humanize_update(changes, type, i18n_context)
    end
  end
end

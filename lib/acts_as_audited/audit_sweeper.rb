class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:
  observe Audit

  def before_create(audit)
    audit.user ||= current_user
  end

  def current_user
    controller.send ActsAsAudited.current_user_method if controller.respond_to?(ActsAsAudited.current_user_method, true)
  end
end


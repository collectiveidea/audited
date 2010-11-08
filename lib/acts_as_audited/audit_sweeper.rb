class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:
  observe Audit

  cattr_accessor :current_user_method
  self.current_user_method = :current_user

  def before_create(audit)
    audit.user ||= current_user
  end

  def current_user
    controller.send self.class.current_user_method if controller.respond_to?(self.class.current_user_method, true)
  end
end


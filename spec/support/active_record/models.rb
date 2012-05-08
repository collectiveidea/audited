require 'cgi'
require File.expand_path('../schema', __FILE__)

module Models
  module ActiveRecord
    class User < ::ActiveRecord::Base
      audited :except => :password

      attr_protected :logins

      def name=(val)
        write_attribute(:name, CGI.escapeHTML(val))
      end
    end

    class BlankUser < ::ActiveRecord::Base
      self.table_name = :users
    end

    class CommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true
    end

    class UnprotectedUser < ::ActiveRecord::Base
      self.table_name = :users
      audited :protect => false
      attr_accessible :name, :username, :password
    end

    class AccessibleUser < ::ActiveRecord::Base
      self.table_name = :users
      attr_accessible :name, :username, :password # declare attr_accessible before calling aaa
      audited
    end

    class NoAttributeProtectionUser < ::ActiveRecord::Base
      self.table_name = :users
      audited
    end

    class UserWithAfterAudit < ::ActiveRecord::Base
      self.table_name = :users
      audited
      attr_accessor :bogus_attr

      def after_audit
        self.bogus_attr = "do something"
      end
    end

    class Company < ::ActiveRecord::Base
      audited
    end

    class Owner < ::ActiveRecord::Base
      self.table_name = 'users'
      has_associated_audits
    end

    class OwnedCompany < ::ActiveRecord::Base
      self.table_name = 'companies'
      belongs_to :owner, :class_name => "Owner"
      attr_accessible :name, :owner # declare attr_accessible before calling aaa
      audited :associated_with => :owner
    end

    class OnUpdateDestroy < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited :on => [:update, :destroy]
    end

    class OnCreateDestroy < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited :on => [:create, :destroy]
    end

    class OnCreateDestroyExceptName < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited :except => :name, :on => [:create, :destroy]
    end

    class OnCreateUpdate < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited :on => [:create, :update]
    end
  end
end

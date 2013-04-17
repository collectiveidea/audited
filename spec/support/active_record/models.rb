require 'cgi'
require File.expand_path('../schema', __FILE__)

module Models
  module ActiveRecord
    class User < ::ActiveRecord::Base
      audited :allow_mass_assignment => true, :except => :password

      attr_protected :logins

      def name=(val)
        write_attribute(:name, CGI.escapeHTML(val))
      end
    end

    class CommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true
    end

    class CommentRequiredUserWithOnCreateOption < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:create]
    end

    class CommentRequiredUserWithOnDestroyOption < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:destroy]
    end

    class CommentRequiredUserWithOnUpdateOption < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:update]
    end

    class CommentRequiredUserWithOnCreateAndDestroyOptions < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:create, :destroy]
    end

    class CommentRequiredUserWithOnCreateAndUpdateOptions < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:create, :update]
    end    

    class CommentRequiredUserWithOnDestroyAndUpdateOptions < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:destroy, :update]
    end

    class CommentRequiredUserWithAllOptions < ::ActiveRecord::Base
      self.table_name = :users
      audited :comment_required => true, :on => [:create, :destroy, :update]
    end

    class AccessibleAfterDeclarationUser < ::ActiveRecord::Base
      self.table_name = :users
      audited
      attr_accessible :name, :username, :password
    end

    class AccessibleBeforeDeclarationUser < ::ActiveRecord::Base
      self.table_name = :users
      attr_accessible :name, :username, :password # declare attr_accessible before calling aaa
      audited
    end

    class NoAttributeProtectionUser < ::ActiveRecord::Base
      self.table_name = :users
      audited :allow_mass_assignment => true
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

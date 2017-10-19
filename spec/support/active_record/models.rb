require 'cgi'
require File.expand_path('../schema', __FILE__)

module Models
  module ActiveRecord
    class User < ::ActiveRecord::Base
      audited allow_mass_assignment: true, except: :password

      attr_protected :logins if respond_to?(:attr_protected)

      def name=(val)
        write_attribute(:name, CGI.escapeHTML(val))
      end
    end

    class DelegatedCompany < ::ActiveRecord::Base
      self.table_name = :companies
      belongs_to :user, class_name: "UserDelegateCompany"
    end

    class UserDelegateCompany < ::ActiveRecord::Base
      self.table_name = :users
      has_many :companies, class_name: 'DelegatedCompany', foreign_key: :owner_id
      after_update :save_company_list
      audited

      def company_list
        @company_string.present? ? @company_string : companies.pluck(:name).join(',')
      end

      def company_list=(val)
        @changed_attributes ||= ActiveSupport::HashWithIndifferentAccess.new
        @changed_attributes['company_list'] = company_list
        @company_string = val
      end

      def save_company_list
        @company_string.split(',').each do |name|
          Company.find_or_create_by(name: name, owner_id: self.id)
        end
      end

			# mock activerecord dirty feature
			def company_list_changed?
				changed_attributes.include?("company_list")
			end

			def company_list_was
				changed_attributes.include?("company_list") ? changed_attributes["company_list"] : __send__("company_list")
			end

			def company_list_change
				[changed_attributes['company_list'], __send__('company_list')] if changed_attributes.include?("company_list")
			end

			def company_list_changes
				[changed_attributes['company_list'], __send__('company_list')] if changed_attributes.include?("company_list")
			end

    end

    class UserOnlyPassword < ::ActiveRecord::Base
      self.table_name = :users
      attribute :non_column_attr if Rails.version >= '5.1'
      audited allow_mass_assignment: true, only: :password
    end

    class CommentRequiredUser < ::ActiveRecord::Base
      self.table_name = :users
      audited comment_required: true
    end

    class AccessibleAfterDeclarationUser < ::ActiveRecord::Base
      self.table_name = :users
      audited
      attr_accessible :name, :username, :password if respond_to?(:attr_accessible)
    end

    class AccessibleBeforeDeclarationUser < ::ActiveRecord::Base
      self.table_name = :users
      attr_accessible :name, :username, :password if respond_to?(:attr_accessible) # declare attr_accessible before calling aaa
      audited
    end

    class NoAttributeProtectionUser < ::ActiveRecord::Base
      self.table_name = :users
      audited allow_mass_assignment: true
    end

    class UserWithAfterAudit < ::ActiveRecord::Base
      self.table_name = :users
      audited
      attr_accessor :bogus_attr, :around_attr

      private

      def after_audit
        self.bogus_attr = "do something"
      end

      def around_audit
        self.around_attr = yield
      end
    end

    class Company < ::ActiveRecord::Base
      audited
    end

    class Company::STICompany < Company
    end


    class Owner < ::ActiveRecord::Base
      self.table_name = 'users'
      has_associated_audits
      has_many :companies, class_name: "OwnedCompany", dependent: :destroy
    end

    class OwnedCompany < ::ActiveRecord::Base
      self.table_name = 'companies'
      belongs_to :owner, class_name: "Owner"
      attr_accessible :name, :owner if respond_to?(:attr_accessible) # declare attr_accessible before calling aaa
      audited associated_with: :owner
    end

    class OnUpdateDestroy < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited on: [:update, :destroy]
    end

    class OnCreateDestroy < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited on: [:create, :destroy]
    end

    class OnCreateDestroyExceptName < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited except: :name, on: [:create, :destroy]
    end

    class OnCreateUpdate < ::ActiveRecord::Base
      self.table_name = 'companies'
      audited on: [:create, :update]
    end
  end
end

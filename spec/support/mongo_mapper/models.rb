require 'cgi'
require 'mongo_mapper'
require File.expand_path('../connection', __FILE__)

module Models
  module MongoMapper
    class User
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      audited :allow_mass_assignment => true, :except => :password

      attr_protected :logins

      def name=(val)
        write_attribute(:name, CGI.escapeHTML(val))
      end
    end

    class CommentRequiredUser
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      audited :comment_required => true
    end

    class AccessibleAfterDeclarationUser
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      audited
      attr_accessible :name, :username, :password
    end

    class AccessibleBeforeDeclarationUser
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      attr_accessible :name, :username, :password # declare attr_accessible before calling aaa
      audited
    end

    class NoAttributeProtectionUser
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      audited :allow_mass_assignment => true
    end

    class UserWithAfterAudit
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      audited
      attr_accessor :bogus_attr

      def after_audit
        self.bogus_attr = "do something"
      end
    end

    class Company
      include ::MongoMapper::Document

      key :name, String
      key :owner_id, ObjectId

      audited
    end

    class Owner
      include ::MongoMapper::Document

      key :name, String
      key :username, String
      key :password, String
      key :activated, Boolean
      key :suspended_at, Time
      key :logins, Integer, :default => 0
      timestamps!

      has_associated_audits
    end

    class OwnedCompany
      include ::MongoMapper::Document

      key :name, String
      key :owner_id, ObjectId

      belongs_to :owner, :class_name => "Owner"
      attr_accessible :name, :owner # declare attr_accessible before calling aaa
      audited :associated_with => :owner
    end

    class OnUpdateDestroy
      include ::MongoMapper::Document

      key :name, String
      key :owner_id, ObjectId

      audited :on => [:update, :destroy]
    end

    class OnCreateDestroy
      include ::MongoMapper::Document

      key :name, String
      key :owner_id, ObjectId

      audited :on => [:create, :destroy]
    end

    class OnCreateDestroyExceptName
      include ::MongoMapper::Document

      key :name, String
      key :owner_id, ObjectId

      audited :except => :name, :on => [:create, :destroy]
    end

    class OnCreateUpdate
      include ::MongoMapper::Document

      key :name, String
      key :owner_id, ObjectId

      audited :on => [:create, :update]
    end

    class RichObjectUser
      include ::MongoMapper::Document

      class Name
        attr_accessor :first_name, :last_name

        def self.from_mongo(value)
          case value
          when String then new(*value.split)
          when self then value
          end
        end

        def self.to_mongo(value)
          case value
          when String then value
          when self then value.to_s
          end
        end

        def initialize(first_name, last_name)
          self.first_name, self.last_name = first_name, last_name
        end

        def to_s
          [first_name, last_name].compact.join(' ')
        end
      end

      key :name, Name

      attr_accessible :name

      audited
    end
  end
end

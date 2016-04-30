module Audited
  module RspecMatchers
    # Ensure that the model is audited.
    #
    # Options:
    # * <tt>associated_with</tt> - tests that the audit makes use of the associated_with option
    # * <tt>only</tt> - tests that the audit makes use of the only option *Overrides <tt>except</tt> option*
    # * <tt>except</tt> - tests that the audit makes use of the except option
    # * <tt>requires_comment</tt> - if specified, then the audit must require comments through the <tt>audit_comment</tt> attribute
    # * <tt>on</tt> - tests that the audit makes use of the on option with specified parameters
    #
    # Example:
    #   it { should be_audited }
    #   it { should be_audited.associated_with(:user) }
    #   it { should be_audited.only(:field_name) }
    #   it { should be_audited.except(:password) }
    #   it { should be_audited.requires_comment }
    #   it { should be_audited.on(:create).associated_with(:user).except(:password) }
    #
    def be_audited
      AuditMatcher.new
    end

    # Ensure that the model has associated audits
    #
    # Example:
    #   it { should have_associated_audits }
    #
    def have_associated_audits
      AssociatedAuditMatcher.new
    end

    class AuditMatcher # :nodoc:
      def initialize
        @options = {}
      end

      def associated_with(model)
        @options[:associated_with] = model
        self
      end

      def only(*fields)
        @options[:only] = fields.flatten
        self
      end

      def except(*fields)
        @options[:except] = fields.flatten
        self
      end

      def requires_comment
        @options[:comment_required] = true
        self
      end

      def on(*actions)
        @options[:on] = actions.flatten
        self
      end

      def matches?(subject)
        @subject = subject
        auditing_enabled? &&
          associated_with_model? &&
          records_changes_to_specified_fields? &&
          comment_required_valid?
      end

      def failure_message
        "Expected #{@expectation}"
      end

      def negative_failure_message
        "Did not expect #{@expectation}"
      end

      alias_method :failure_message_when_negated, :negative_failure_message

      def description
        description = "audited"
        description += " associated with #{@options[:associated_with]}" if @options.key?(:associated_with)
        description += " only => #{@options[:only].join ', '}"          if @options.key?(:only)
        description += " except => #{@options[:except].join(', ')}"     if @options.key?(:except)
        description += " requires audit_comment"                        if @options.key?(:comment_required)

        description
      end

      protected

      def expects(message)
        @expectation = message
      end

      def auditing_enabled?
        expects "#{model_class} to be audited"
        model_class.respond_to?(:auditing_enabled) && model_class.auditing_enabled
      end

      def model_class
        @subject.class
      end

      def associated_with_model?
        expects "#{model_class} to record audits to associated model #{@options[:associated_with]}"
        model_class.audit_associated_with == @options[:associated_with]
      end

      def records_changes_to_specified_fields?
        if @options[:only] || @options[:except]
          if @options[:only]
            except = model_class.column_names - @options[:only].map(&:to_s)
          else
            except = model_class.default_ignored_attributes + Audited.ignored_attributes
            except |= @options[:except].collect(&:to_s) if @options[:except]
          end

          expects "non audited columns (#{model_class.non_audited_columns.inspect}) to match (#{expect})"
          model_class.non_audited_columns =~ except
        else
          true
        end
      end

      def comment_required_valid?
        if @options[:comment_required]
          @subject.audit_comment = nil

          expects "to be invalid when audit_comment is not specified"
          @subject.valid? == false && @subject.errors.key?(:audit_comment)
        else
          true
        end
      end
    end

    class AssociatedAuditMatcher # :nodoc:
      def matches?(subject)
        @subject = subject

        association_exists?
      end

      def failure_message
        "Expected #{model_class} to have associated audits"
      end

      def negative_failure_message
        "Expected #{model_class} to not have associated audits"
      end

      alias_method :failure_message_when_negated, :negative_failure_message

      def description
        "has associated audits"
      end

      protected

      def model_class
        @subject.class
      end

      def reflection
        model_class.reflect_on_association(:associated_audits)
      end

      def association_exists?
        !reflection.nil? &&
          reflection.macro == :has_many &&
          reflection.options[:class_name] == Audited.audit_class.name
      end
    end
  end
end

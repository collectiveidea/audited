# Copyright (c) 2010 Brandon Keepers
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# To get started, please review ActsAsAudited::Adapters::ActiveRecord::Auditor::ClassMethods#acts_as_audited
module ActsAsAudited
  VERSION = '3.0.0'

  class << self
    attr_accessor :ignored_attributes, :current_user_method, :audit_class
  end
  @ignored_attributes ||= ['lock_version',
                          'created_at',
                          'updated_at',
                          'created_on',
                          'updated_on']

  # The method to be called to return the current user for logging in the audits.
  @current_user_method = :current_user
end

require 'acts_as_audited/adapters/active_record'

if defined?(ActionController) and defined?(ActionController::Base)
  require 'acts_as_audited/audit_sweeper'

  ActionController::Base.class_eval do
    cache_sweeper :audit_sweeper
  end
end

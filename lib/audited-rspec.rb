# frozen_string_literal: true
require 'audited/rspec_matchers'
module RSpec
  module Matchers
    include Audited::RspecMatchers
  end
end

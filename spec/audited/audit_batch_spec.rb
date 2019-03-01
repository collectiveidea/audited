require "spec_helper"
require "pry"

SingleCov.covered!

describe Audited::AuditBatch do
  let(:count) { 10 }
  let!(:users) do
    count.times do |i|
      Models::ActiveRecord::User.create name: "user #{i}"
    end
    Models::ActiveRecord::User.all
  end

  describe "#create" do
    it "should create a batch of audits for all models" do
      current_audit_count = Audited.audit_class.count
      audited_changes = { name: "Updated User" }
      Audited::AuditBatch.new(users, audited_changes).create

      users.each do |user|
        latest_audit = user.audits.first

        expect(user.name).to eq(audited_changes[:name])
        expect(latest_audit).to be_a Audited::Audit
        expect(latest_audit.audited_changes).to eq audited_changes
      end
      expect(Audited.audit_class.count).to eq(current_audit_count + count)
    end
  end
end

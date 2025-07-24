require "spec_helper"

describe Audited do
  describe "#store" do
    describe "maintains state of store" do
      let(:current_user) { Models::ActiveRecord::User.new(name: 'Some User', username: 'some_username') }

      it "can store and retrieve current_user" do
        expect(Audited.store[:current_user]).to be_nil

        Audited.store[:current_user] = current_user

        expect(Audited.store[:current_user]).to eq(current_user)
      end

      it "checks store is not nil" do
        expect(Audited.store).not_to be_nil
      end
    end
  end
end

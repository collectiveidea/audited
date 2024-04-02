require "spec_helper"

describe Audited do
  describe "#store" do
    describe "maintains state of store" do
      let(:current_user) { Models::ActiveRecord::User.new(name: 'Some User', username: 'some_username') }
      before { Audited.store[:current_user] = current_user }

      it "checks store is not nil" do
        expect(Audited.store[:current_user]).to eq(current_user)
      end
    end
  end
end

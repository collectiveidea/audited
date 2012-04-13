require 'spec_helper'

describe ActsAsAudited::Sweeper do
  subject{ described_class.instance }

  let(:controller){ mock('Controller').as_null_object }
  let!(:user){ create_user }
  let(:audit){ ActsAsAudited.audit_class.new }

  before do
    subject.stub!(:controller).and_return(controller)
    ActsAsAudited.current_user_method = :current_user
  end

  describe :before_create do
    it 'sets the current user' do
      controller.stub!(:current_user).and_return(user)
      subject.before_create(audit)
      audit.user_type.should == user.class.name
      audit.user_id.should == user.id
    end

    it 'supports custom users for sweepers' do
      ActsAsAudited.current_user_method = :custom_user
      controller.stub!(:custom_user).and_return(user)
      subject.before_create(audit)
      audit.user_type.should == user.class.name
      audit.user_id.should == user.id
    end

    it 'records the remote address responsible for the change' do
      controller.stub!(:current_user).and_return(user)
      request = mock('Request').as_null_object
      request.stub!(:ip).and_return('1.2.3.4')
      controller.stub!(:request).and_return(request)
      subject.before_create(audit)
      audit.remote_address.should == '1.2.3.4'
    end

    it 'does not set a user when there is no current user' do
      controller.stub!(:current_user).and_return(nil)
      subject.before_create(audit)
      audit.user_type.should be_nil
      audit.user_id.should be_nil
    end
  end
end

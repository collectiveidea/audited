require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class AuditsController < ActionController::Base
  audit Company
  
  def audit
    @company = Company.create
    render :nothing => true
  end
  
private
  attr_accessor :current_user
end
AuditsController.view_paths = [File.dirname(__FILE__)]
ActionController::Routing::Routes.draw {|m| m.connect ':controller/:action/:id' }

class AuditsControllerTest < ActionController::TestCase

  should "call acts as audited on non audited models" do
    Company.should be_kind_of(CollectiveIdea::Acts::Audited::SingletonMethods)
  end
  
  should "audit user" do
    user = @controller.send(:current_user=, create_user)
    lambda { post :audit }.should change { Audit.count }
    assigns(:company).audits.last.user.should == user
  end
  
end
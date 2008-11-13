# require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
# require 'spec/rails'
# 
# class AuditsController < ActionController::Base
#   audit Company
#   attr_accessor :current_user
#   
#   def audit
#     @company = Company.create
#     render :nothing => true
#   end
#   
# end
# AuditsController.view_paths = [File.expand_path(File.dirname(__FILE__) + "/../fixtures")]
# ActionController::Routing::Routes.draw {|m| m.connect ':controller/:action/:id' }
# 
# describe "AuditSweeper" do
#   before do
#     @controller = AuditsController.new
#     @controller.logger = Logger.new(nil)
#     @request    = ActionController::TestRequest.new
#     @response   = ActionController::TestResponse.new
#     @request.host = "www.example.com"
#   end
#   
#   it "calls acts as audited on non audited models" do
#     Company.should be_kind_of(CollectiveIdea::Acts::Audited::SingletonMethods)
#   end
#   
#   it "audits user" do
#     user = @controller.current_user = create_user
#     assert_difference Audit, :count do
#       post :audit
#     end
#     assigns(:company).audits.last.user.should == user
#   end
#   
# end
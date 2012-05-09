module Api

  #=== Description
  # TODO: write a description
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class GroupsApiController < MainApiController
    # TODO: WRITE ME!!!
  
  def create
    render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
  end
    
  def destroy
    render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
  end
  
  def update
    render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
  end
  
  def index
    render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
  end
  
  def show
    render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
  end
    
  end # end GroupsApiController
end
class VisitorController < ApplicationController
  def create
    Visitor.create_with_random_uuid(request.remote_ip)
  end

  def index
    #fill in index
  end

  def update
    #fill in read
  end

  def destroy
    #fill in read
  end

  def show
    #fill in show with users solutions?
  end
end

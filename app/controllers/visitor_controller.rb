class VisitorController < ApplicationController
  def create
    Visitor.create_with_random_uuid(request.remote_ip)
  end

  def index
    redirect_to(action: :create)
  end

  def update
    # fill in read
  end

  def destroy
    @visitor = Visitor.find(params[:id])
    @visitor.destroy
  end

  def show
    @visitor = Visitor.find(params[:id])
  end
end

class AutomationScenarioController < ApplicationController
  def create
    Visitor.create_with_random_uuid(visitor_params)
  end

  def read
    #fill in read
  end

  def update
    #fill in read
  end

  def delete
    #fill in read
  end
end

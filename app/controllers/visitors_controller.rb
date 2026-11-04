class VisitorsController < ApplicationController
  # Both actions write visitor and scenario rows (show calls create), so
  # throttle them together on one per-IP counter.
  rate_limit to: 30, within: 1.minute, only: %i[show create]

  def show
    # to support the GET method
    create
  end

  def create
    visitor = Visitor.create_with_random_uuid(request.remote_ip)
    automation_scenario = visitor.automation_scenarios.create!
    store_current_visitor visitor
    redirect_to automation_scenario
  end
end

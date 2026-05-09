require 'smoke_helper'

# Full end-to-end API flow without a browser: visitor auth → scenario creation → math verification.
# These tests exercise the auth stack, database connectivity, and core break-even logic.
RSpec.describe "Visitor API flow", :smoke do
  let(:token) do
    response = smoke_v1_post("/api/visitor")
    expect(response.code.to_i).to eq(201), "Expected 201 from POST /api/visitor, got #{response.code}: #{response.body}"
    response['Access-Token'].tap { |t| expect(t).not_to be_nil, "Expected Access-Token header" }
  end

  describe "visitor auth" do
    it "issues a JWT on visitor creation" do
      expect(token).not_to be_nil
    end

    it "grants access to scenarios list" do
      response = smoke_v1_get("/api/automation_scenarios", token: token)
      expect(response.code.to_i).to eq(200)
    end
  end

  describe "scenario creation" do
    let(:scenario_id) do
      response = smoke_v1_post(
        "/api/automation_scenarios",
        body: { name: "smoke-test", iteration_count: 100 },
        token: token
      )
      expect(response.code.to_i).to eq(201), "Expected 201 creating scenario, got #{response.code}: #{response.body}"
      JSON.parse(response.body)['id']
    end

    it "creates a scenario and returns its id" do
      expect(scenario_id).not_to be_nil
    end

    it "returns the scenario in the list" do
      id = scenario_id
      response = smoke_v1_get("/api/automation_scenarios", token: token)
      ids = JSON.parse(response.body).map { |s| s['id'] }
      expect(ids).to include(id)
    end
  end

  describe "break-even math" do
    # manual:    $0 upfront, $10/iteration  → cost(n) = 10n
    # automated: $100 upfront, $2/iteration → cost(n) = 100 + 2n
    # intersection: 10n = 100 + 2n  →  n = 12.5, cost = 125.0
    let(:scenario_id) do
      response = smoke_v1_post(
        "/api/automation_scenarios",
        body: { name: "smoke-math", iteration_count: 100 },
        token: token
      )
      JSON.parse(response.body)['id']
    end

    before do
      smoke_v1_post(
        "/api/automation_scenarios/#{scenario_id}/solutions",
        body: { initial_cost: 0, iteration_cost: 10 },
        token: token
      )
      smoke_v1_post(
        "/api/automation_scenarios/#{scenario_id}/solutions",
        body: { initial_cost: 100, iteration_cost: 2 },
        token: token
      )
    end

    it "returns a 200 from the intersections endpoint" do
      response = smoke_v1_get("/api/automation_scenarios/#{scenario_id}/intersections", token: token)
      expect(response.code.to_i).to eq(200)
    end

    it "returns a 200 from the differences endpoint" do
      response = smoke_v1_get("/api/automation_scenarios/#{scenario_id}/differences", token: token)
      expect(response.code.to_i).to eq(200)
    end

    it "calculates the correct break-even point" do
      response = smoke_v1_get("/api/automation_scenarios/#{scenario_id}/intersections", token: token)
      intersections = JSON.parse(response.body)

      # intersection is [x, y] where x=iteration, y=cost
      point = intersections.first&.fetch("intersection")
      expect(point).not_to be_nil, "Expected at least one intersection"
      expect(point[0].to_f).to be_within(0.01).of(12.5)
      expect(point[1].to_f).to be_within(0.01).of(125.0)
    end
  end
end

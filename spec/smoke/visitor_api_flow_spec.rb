require 'smoke_helper'

# Full end-to-end API flow without a browser:
# visitor auth -> scenario creation -> math verification.
# These tests exercise the auth stack, database connectivity,
# and core break-even logic.
RSpec.describe 'Visitor API flow', :smoke do
  let(:visitor_response) do
    response = smoke_v1_post('/api/visitor')
    msg = 'Expected 201 from POST /api/visitor, ' \
          "got #{response.code}: #{response.body}"
    expect(response.code.to_i).to eq(201), msg
    response
  end

  let(:token) do
    visitor_response['Access-Token'].tap do |t|
      expect(t).not_to be_nil, 'Expected Access-Token header'
    end
  end

  describe 'visitor auth' do
    it 'issues a JWT on visitor creation' do
      expect(token).not_to be_nil
    end

    it 'returns a valid visitor body' do
      validate_schema!('visitor.json', visitor_response.body)
    end

    it 'grants access to scenarios list' do
      response = smoke_v1_get('/api/automation_scenarios', token: token)
      expect(response.code.to_i).to eq(200)
    end

    it 'returns a valid scenarios list body' do
      response = smoke_v1_get('/api/automation_scenarios', token: token)
      validate_schema!('automation_scenarios.json', response.body)
    end
  end

  describe 'scenario creation' do
    let(:scenario_response) do
      smoke_v1_post(
        '/api/automation_scenarios',
        body: { name: 'smoke-test', iteration_count: 100 },
        token: token
      ).tap do |r|
        msg = "Expected 201 creating scenario, got #{r.code}: #{r.body}"
        expect(r.code.to_i).to eq(201), msg
      end
    end

    let(:scenario_id) { JSON.parse(scenario_response.body)['id'] }

    it 'creates a scenario and returns its id' do
      expect(scenario_id).not_to be_nil
    end

    it 'returns a valid scenario body' do
      validate_schema!('automation_scenario.json', scenario_response.body)
    end

    it 'returns the scenario in the list' do
      id = scenario_id
      response = smoke_v1_get('/api/automation_scenarios', token: token)
      ids = JSON.parse(response.body).map { |s| s['id'] }
      expect(ids).to include(id)
    end
  end

  describe 'break-even math' do
    # manual:    $10 upfront, $10/iteration -> cost(n) = 10 + 10n
    # automated: $90 upfront, $2/iteration  -> cost(n) = 90 + 2n
    # intersection: 10 + 10n = 90 + 2n -> n = 10, cost = 110
    # Solution#initial_cost has a `greater_than: 0` validation, so the
    # manual scenario uses 10 rather than 0.
    let(:scenario_id) do
      create_smoke_scenario(name: 'smoke-math', iteration_count: 100)
    end

    before do
      create_smoke_solution(scenario_id, initial_cost: 10, iteration_cost: 10)
      create_smoke_solution(scenario_id, initial_cost: 90, iteration_cost: 2)
    end

    it 'returns a 200 from the intersections endpoint' do
      url = "/api/automation_scenarios/#{scenario_id}/intersections"
      response = smoke_v1_get(url, token: token)
      expect(response.code.to_i).to eq(200)
    end

    it 'returns a valid intersections body' do
      url = "/api/automation_scenarios/#{scenario_id}/intersections"
      response = smoke_v1_get(url, token: token)
      validate_schema!('solution_intersections.json', response.body)
    end

    it 'returns a 200 from the differences endpoint' do
      url = "/api/automation_scenarios/#{scenario_id}/differences"
      response = smoke_v1_get(url, token: token)
      expect(response.code.to_i).to eq(200)
    end

    it 'returns a valid differences body' do
      url = "/api/automation_scenarios/#{scenario_id}/differences"
      response = smoke_v1_get(url, token: token)
      validate_schema!('solution_differences.json', response.body)
    end

    it 'calculates the correct break-even point' do
      url = "/api/automation_scenarios/#{scenario_id}/intersections"
      intersections = JSON.parse(smoke_v1_get(url, token: token).body)

      # intersection is [x, y] where x=iteration, y=cost
      point = intersections.first&.fetch('intersection')
      expect(point).not_to be_nil, 'Expected at least one intersection'
      expect(point[0].to_f).to be_within(0.01).of(10.0)
      expect(point[1].to_f).to be_within(0.01).of(110.0)
    end
  end
end

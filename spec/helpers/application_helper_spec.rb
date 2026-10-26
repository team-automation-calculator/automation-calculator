require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#flash_alert_class' do
    it 'maps a notice to the Bootstrap success class' do
      expect(helper.flash_alert_class(:notice)).to eq('alert-success')
    end

    it 'maps an alert to the Bootstrap danger class' do
      expect(helper.flash_alert_class('alert')).to eq('alert-danger')
    end

    it 'falls back to the info class for other flash types' do
      expect(helper.flash_alert_class(:warning)).to eq('alert-info')
    end
  end
end

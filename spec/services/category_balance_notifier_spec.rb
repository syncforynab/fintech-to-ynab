require 'rails_helper'

RSpec.describe CategoryBalanceNotifier, type: :service do

  let(:notifier) { CategoryBalanceNotifier.new }

  describe '#discover_services' do
    subject { notifier.discover_services }

    context 'when no services are defined' do
      before { ENV['PUSHBULLET_API_KEY'] = nil }
      it 'should not discover any services' do
        expect(notifier).not_to receive(:add_service)
        subject
      end
    end

    context 'when a service is defined' do
      let(:pushbullet_key) { SecureRandom.hex }
      before { ENV['PUSHBULLET_API_KEY'] = pushbullet_key }
      it 'should discover a service' do
        expect(notifier).to receive(:add_service).with(CategoryBalanceNotifier::Pushbullet, { api_key: pushbullet_key })
        subject
      end
    end
  end
end

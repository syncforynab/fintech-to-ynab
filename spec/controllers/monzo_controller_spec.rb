require 'rails_helper'

RSpec.describe MonzoController, type: :controller do
  describe '#receive' do
    subject { post :receive, body: body.to_json, format: :json }

    context 'when sending no body' do
      let(:body) { {} }
      it { is_expected.to have_http_status(200) }
      it { is_expected.to have_json({'error' => 'unsupported_type'}) }
    end

    context 'when sending an unsupported webhook type' do
      let(:body) { { type: :not_supported } }
      it { is_expected.to have_http_status(200) }
      it { is_expected.to have_json({'error' => 'unsupported_type'}) }
    end

    context 'when sending an amount of 0' do
      let(:body) { { type: 'transaction.created', data: { amount: 0 } } }
      it { is_expected.to have_http_status(200) }
      it { is_expected.to have_json({'error' => 'zero_value'}) }
    end

    context 'when sending a declined transaction' do
      let(:body) { { type: 'transaction.created', data: { decline_reason: 'any reason' } } }
      it { is_expected.to have_http_status(200) }
      it { is_expected.to have_json({'error' => 'declined'}) }
    end
  end
end

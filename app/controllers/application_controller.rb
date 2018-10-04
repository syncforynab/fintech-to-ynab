class ApplicationController < ActionController::API
  before_action :verify_token, except: [:home, :ping]

  def home
    redirect_to 'https://github.com/fintech-to-ynab/fintech-to-ynab'
  end

  def ping
    render json: { pong: true }
  end

  private

  def verify_token
    render json: { error: :unauthorised }, status: 401 if ENV['URL_SECRET'].present? && ENV['URL_SECRET'] != params[:secret]
  end
end

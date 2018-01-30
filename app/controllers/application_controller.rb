class ApplicationController < ActionController::API

  before_action :verify_token

  def home
    redirect_to 'https://github.com/scottrobertson/fintech-to-ynab'
  end

  def ping
    { pong: true }
  end

  private

  def verify_token
    # @todo verify the token if one is set in ENV
  end
end

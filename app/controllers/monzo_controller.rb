class MonzoController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)
    import = ::F2ynab::Webhooks::Monzo.new(webhook).import
    if import[:error]
      render json: import, status: 400
    else
      render json: import
    end
  end
end

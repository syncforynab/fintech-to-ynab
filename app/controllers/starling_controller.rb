class StarlingController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)
    import = ::F2ynab::Webhooks::Starling.new(webhook, ynab_account_id: params[:ynab_account_id]).import
    if import.try(:id) || import.try(:[], :warning)
      render json: import
    else
      render json: import, status: 400
    end
  end
end

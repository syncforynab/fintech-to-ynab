class StarlingController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)

    ynab_budget_id = params[:ynab_budget_id] || ENV['YNAB_BUDGET_ID']
    ynab_account_id = params[:ynab_account_id] || ENV['YNAB_STARLING_ACCOUNT_ID']
    ynab_client = ::F2ynab::YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], ynab_budget_id, ynab_account_id)

    import = ::F2ynab::Webhooks::Starling.new(ynab_client, webhook,
      skip_foreign_currency_flag: ENV['SKIP_FOREIGN_CURRENCY_FLAG'].present?,
    ).import

    if import.try(:id) || import.try(:[], :warning)
      render json: import
    else
      render json: import, status: 400
    end
  end
end

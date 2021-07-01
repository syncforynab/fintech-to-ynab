class Starlingv2Controller < ApplicationController
  SUPPORTED_SOURCES = %w[
        MASTER_CARD
        CASH_WITHDRAWAL
        DIRECT_CREDIT
        DIRECT_DEBIT
        DIRECT_DEBIT_DISPUTE
        FASTER_PAYMENTS_IN
        FASTER_PAYMENTS_OUT
        FASTER_PAYMENTS_REVERSAL
        INTEREST_PAYMENT
        INTERNAL_TRANSFER
        OVERDRAFT_INTEREST_WAIVED
        NOSTRO_DEPOSIT
        ON_US_PAY_ME
        STRIPE_FUNDING
      ]

  def feed
    webhook = JSON.parse(request.body.read, symbolize_names: true)
    
    return { warning: :unsupported_type } unless webhook[:content][:source].in?(SUPPORTED_SOURCES)


    ynab_budget_id = params[:ynab_budget_id] || ENV['YNAB_BUDGET_ID']
    ynab_account_id = params[:ynab_account_id] || ENV['YNAB_STARLING_ACCOUNT_ID']
    ynab_client = ::F2ynab::YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], ynab_budget_id, ynab_account_id)
    skip_foreign_currency_flag = ENV['SKIP_FOREIGN_CURRENCY_FLAG'].present?

    payee_name = webhook[:content][:counterPartyName]
    amount = (webhook[:content][:amount][:minorUnits].to_f * 10).to_i
    amount *= -1 if webhook[:content][:direction] == 'OUT'
    description = webhook[:content][:reference]
    
    flag = nil
    foreign_transaction = webhook[:content][:amount][:currency] != 'GBP'
    if foreign_transaction && !skip_foreign_currency_flag
      flag = 'orange'
    end

    import = ::F2ynab::YNAB::TransactionCreator.new(
      ynab_client,
      id: "S:#{webhook[:content][:feedItemUid]}",
      date: Time.parse(webhook[:content][:transactionTime]).to_date,
      amount: amount,
      payee_name: payee_name,
      description: description.strip,
      cleared: !foreign_transaction,
      flag: flag
    ).create

    if import.try(:id) || import.try(:[], :warning)
      render json: import
    else
      render json: import, status: 400
    end
  end
end

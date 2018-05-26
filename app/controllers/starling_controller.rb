class StarlingController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)

    case webhook[:webhookType]
    when 'TRANSACTION_CARD', 'TRANSACTION_AUTH_FULL_REVERSAL', 'TRANSACTION_FASTER_PAYMENT_OUT', 'TRANSACTION_FASTER_PAYMENT_IN'
      payee_name = webhook[:content][:counterParty]
      amount = (webhook[:content][:amount].to_f * 1000).to_i
      description = webhook[:content][:forCustomer].to_s
      flag = nil

      foreign_transaction = webhook[:content][:sourceCurrency] != 'GBP'
      flag = 'orange' if foreign_transaction
    else
      return render json: { error: :unsupported_type }
    end

    ynab_creator = YNAB::TransactionCreator.new(
      date: Time.parse(webhook[:timestamp]).to_date,
      amount: amount,
      payee_name: payee_name,
      description: description.strip,
      cleared: !foreign_transaction,
      flag: flag,
      account_id: ENV['YNAB_STARLING_ACCOUNT_ID']
    )

    create = ynab_creator.create
    if create.try(:id).present?
      render json: create
    else
      render json: create, status: 400
    end

  end
end

class MonzoController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)

    return render json: { error: :unsupported_type } unless webhook[:type] == 'transaction.created'
    return render json: { error: :zero_value } if webhook[:data][:amount] == 0
    return render json: { error: :declined } if webhook[:data][:decline_reason].present?

    payee_name = webhook[:data][:merchant].try(:[], :name)
    payee_name ||= webhook[:data][:counterparty][:name] if webhook[:data][:counterparty].present?
    payee_name ||= 'Topup' if webhook[:data][:metadata][:is_topup]
    payee_name ||= webhook[:data][:description]

    description = ''
    flag = nil

    foreign_transaction = webhook[:data][:local_currency] != webhook[:data][:currency]
    if foreign_transaction
      money = Money.new(webhook[:data][:local_amount].abs, webhook[:data][:local_currency])
      description.prepend("(#{money.format}) ")
      flag = 'orange'
    end

    description.prepend("#{webhook[:data][:merchant][:emoji]} ") if webhook[:data][:merchant].try(:[], :emoji)
    description << webhook[:data][:merchant][:metadata][:suggested_tags] if webhook[:data][:merchant].try(:[], :metadata).try(:[], :suggested_tags)

    ynab_creator = YNAB::TransactionCreator.new(
      date: Time.parse(webhook[:data][:created]).to_date,
      amount: webhook[:data][:amount] * 10,
      payee_name: payee_name,
      description: description.strip,
      cleared: !foreign_transaction,
      flag: flag
    )

    create = ynab_creator.create
    if create.try(:id).present?
      render json: create
    else
      render json: create, status: 400
    end
  end
end

class MonzoController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)

    return render json: { error: :unsupported_type }, status: 400 unless webhook[:type] == 'transaction.created'

    payee_name = webhook[:data][:merchant].try(:[], :name)
    payee_name ||= webhook[:data][:counterparty][:name] if webhook[:data][:counterparty].present?
    payee_name ||= 'Topup' if webhook[:data][:metadata][:is_topup]
    payee_name ||= webhook[:data][:description]
    description = ''

    foreign_transaction = webhook[:data][:local_currency] != webhook[:data][:currency]
    if foreign_transaction
      money = Money.new(webhook[:data][:local_amount].abs, webhook[:data][:local_currency])
      description.prepend("(#{money.format}) ")
    end

    description.prepend("#{webhook[:data][:merchant][:emoji]} ") if webhook[:data][:merchant].try(:[], :emoji)
    description << " #{webhook[:data][:merchant][:metadata][:suggested_tags]}" if webhook[:data][:merchant].try(:[], :metadata).try(:[], :suggested_tags)

    ynab_creator = YNAB::TransactionCreator.new(
      Time.parse(webhook[:data][:created]).to_date,
      webhook[:data][:amount] * 10,
      payee_name,
      description.strip,
      cleared: !foreign_transaction
    )

    create = ynab_creator.create
    if create.try(:[], :transaction).present?
      render json: create[:transaction]
    else
      render json: { error: create[:error] }, status: 400
    end
  end
end

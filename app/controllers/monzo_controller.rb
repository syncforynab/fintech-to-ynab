class MonzoController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)

    return render json: { error: :unsupported_type }, status: 400 unless webhook[:type] == 'transaction.created'

    payee_name = webhook[:data][:merchant].try(:[], :name)
    payee_name ||= webhook[:data][:counterparty][:name] if webhook[:data][:counterparty].present?
    payee_name ||= 'Topup' if webhook[:data][:metadata][:is_topup]
    payee_name ||= webhook[:data][:description]

    description = webhook[:data][:description]
    description << " #{webhook[:merchant][:emoji]}" if webhook[:merchant].try(:[], :emoji)
    description << " #{webhook[:merchant][:suggested_tags]}" if webhook[:merchant].try(:[], :suggested_tags)

    ynab_creator = YNABTransactionCreator.new(
      Time.parse(webhook[:data][:created]).to_date,
      webhook[:data][:amount],
      payee_name,
      description,
      cleared: webhook[:data][:local_currency] == webhook[:data][:currency]
    )

    create = ynab_creator.create
    if create.try(:[], :transaction).present?
      render json: transaction
    else
      render json: { error: create[:error] }, status: 400
    end
  end
end

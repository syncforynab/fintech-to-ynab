class MonzoController < ApplicationController
  def receive
    webhook = JSON.parse(request.body.read, symbolize_names: true)

    return render json: { error: :unsupported_type } unless webhook[:type] == 'transaction.created'
    return render json: { error: :zero_value } if webhook[:data][:amount] == 0

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
    description << " #{webhook[:data][:merchant][:metadata][:suggested_tags]}" if webhook[:data][:merchant].try(:[], :metadata).try(:[], :suggested_tags)

    ynab_creator = YNAB::TransactionCreator.new(
      date: Time.parse(webhook[:data][:created]).to_date,
      amount: webhook[:data][:amount] * 10,
      payee_name: payee_name,
      description: description.strip,
      cleared: !foreign_transaction,
      flag: flag
    )

    create = ynab_creator.create
    if create.try(:[], :transaction).present?

      # Quick and dirty YNAB -> Monzo Feed Item integration.
      # @todo clean this up
      if create[:transaction][:category_id].present? && ENV['MONZO_ACCESS_TOKEN'].present?
        ynab_client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'])
        ynab_category = ynab_client.category(create[:transaction][:category_id])

        monzo_feed_item = {
        	account_id: webhook[:data][:account_id],
        	type: "basic",
        	url: "https://app.youneedabudget.com/#{ynab_client.selected_budget_id}/accounts/#{ynab_client.selected_account_id}",
        	params: {
        		title: "YNAB: #{ynab_category[:name]}",
        		body: "You have £#{(ynab_category[:balance]/1000).to_f.round(2)} remaining this month.",
        		image_url: "https://api.youneedabudget.com/favicon.ico"
        	}
        }

        begin
          monzo = RestClient.post('https://api.monzo.com/feed', monzo_feed_item, { 'Authorization' => "Bearer #{ENV['MONZO_ACCESS_TOKEN']}" })
        rescue => e
          raise e.response.body.to_yaml
        end
      end


      render json: create[:transaction]
    else
      render json: { error: create[:error] }, status: 400
    end
  end
end

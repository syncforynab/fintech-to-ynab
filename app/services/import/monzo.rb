class Import::Monzo
  BASE_URL = 'https://api.monzo.com'

  def initialize(access_token, monzo_account_id, ynab_account_id, from: 1.year.ago)
    @access_token = access_token
    @monzo_account_id = monzo_account_id
    @ynab_account_id = ynab_account_id
    @from = from
  end

  def import
    transactions_to_create = []
    transactions.reject { |t| t[:decline_reason].present? || t[:amount] == 0 }.each do |transaction|
      payee_name = transaction[:merchant].try(:[], :name)
      payee_name ||= transaction[:counterparty][:name] if transaction[:counterparty].present?
      payee_name ||= 'Topup' if transaction[:is_load]
      payee_name ||= transaction[:description]

      description = ''
      flag = nil

      foreign_transaction = transaction[:local_currency] != transaction[:currency]
      if foreign_transaction
        money = Money.new(transaction[:local_amount].abs, transaction[:local_currency])
        description.prepend("(#{money.format}) ")
        flag = 'orange' unless ENV['SKIP_FOREIGN_CURRENCY_FLAG'].present?
      end

      unless ENV['SKIP_EMOJI'].present?
        description.prepend("#{transaction[:merchant][:emoji]} ") if transaction[:merchant].try(:[], :emoji)
      end

      unless ENV['SKIP_TAGS'].present?
        description << transaction[:merchant][:metadata][:suggested_tags] if transaction[:merchant].try(:[], :metadata).try(:[], :suggested_tags)
      end

      transactions_to_create << {
        id: "M#{transaction[:id]}",
        amount: transaction[:amount] * 10,
        payee_name: payee_name,
        date: Time.parse(transaction[:created]).to_date,
        description: description,
        cleared: transaction[:settled].present? ? 'Cleared' : 'Uncleared',
        flag: flag
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end

  private

  def transactions
    since = @from.present? ? "&since=#{@from.strftime('%FT%TZ')}" : nil
    get("/transactions?account_id=#{@monzo_account_id}#{since}&expand[]=merchant")[:transactions]
  end

  def get(url)
    parse_response(RestClient.get(BASE_URL + url, { 'Authorization' => "Bearer #{@access_token}" }))
  end

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)
  end
end

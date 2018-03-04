class Import::Teller

  BASE_URL = "https://api.teller.io"

  def initialize(access_token, teller_account_id, ynab_account_id)
    @access_token = access_token
    @teller_account_id = teller_account_id
    @ynab_account_id = ynab_account_id
  end

  def import
    transactions_to_create = []
    transactions.select{|t| Date.parse(t[:date]) <= Date.today }.each do |transaction|
      transactions_to_create << {
        amount: (transaction[:amount].to_f * 1000).to_i,
        payee_name: transaction[:counterparty],
        date: Date.parse(transaction[:date]),
        description: transaction[:description]
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end

  def transactions
    get("/accounts/#{@teller_account_id}/transactions")
  end

  def accounts
    get('/accounts')
  end

  private

  def get(url)
    parse_response(RestClient.get(BASE_URL + url, { 'Authorization' => "Bearer #{@access_token}" }))
  end

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)
  end
end

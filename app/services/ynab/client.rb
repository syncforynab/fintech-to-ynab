class YNAB::Client

  BASE_URL = 'https://api.youneedabudget.com/papi/v1'

  def initialize(access_token, budget_id = nil, account_id = nil)
    @access_token = access_token
    @budget_id = budget_id || ENV['YNAB_BUDGET_ID']
    @account_id = account_id || ENV['YNAB_ACCOUNT_ID']
  end

  def budgets
    @_budgets ||= get('/budgets')[:budgets]
  end

  def accounts
    @_accounts ||= get("/budgets/#{selected_budget_id}/accounts")[:accounts]
  end

  def payees
    @_payees ||= get("/budgets/#{selected_budget_id}/payees")[:payees]
  end

  def transactions
    @_transactions ||= get("/budgets/#{selected_budget_id}/transactions")[:transactions]
  end

  def create_transaction(payee_id: nil, payee_name: nil, category_id: nil, amount: nil, cleared: nil, date: nil, memo: nil)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{selected_budget_id}/transactions", {
      transaction: {
        account_id: selected_account_id,
        date: date.to_s,
        amount: amount,
        category_id: category_id,
        payee_id: payee_id,
        payee_name: payee_name,
        cleared: cleared ? "Cleared" : 'Uncleared',
        memo: memo
      }
    }, {
      'Authorization' => "Bearer #{@access_token}"
    }))
  end

  def create_transactions(transactions)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{selected_budget_id}/transactions/bulk", {
      transactions: transactions
    }, {
      'Authorization' => "Bearer #{@access_token}"
    }))
  end

  def get(url)
    parse_response(RestClient.get(BASE_URL + url, { 'Authorization' => "Bearer #{@access_token}" }))
  end

  def selected_budget_id
    @budget_id || budgets.first[:id]
  end

  def selected_account_id
    @account_id || accounts.reject{|a| a[:closed]}.select{|a| a[:type] == 'Checking'}.first[:id]
  end

  def lookup_payee_id(payee_name)
    @_payee_names ||= payees.map {|p| { id: p[:id], name: p[:name] } }
    @_fuzzy_match ||= FuzzyMatch.new(@_payee_names, read: :name)

    payee_found = @_fuzzy_match.find(payee_name.to_s)
    payee_found = nil if payee_found.present? && payee_name.pair_distance_similar(payee_found[:name]) < 0.5
    payee_found.try(:[], :id)
  end

  def lookup_category_id(payee_id)
    transactions.select{|a| a[:payee_id] == payee_id }.last.try(:[], :category_id)
  end

  protected

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)[:data]
  end

end

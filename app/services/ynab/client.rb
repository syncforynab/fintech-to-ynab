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

  def transactions
    @_transactions ||= get("/budgets/#{selected_budget_id}/transactions")[:transactions]
  end

  def categories
    @_categories ||= get("/budgets/#{selected_budget_id}/categories")[:category_groups]
  end

  def category(category_id)
    get("/budgets/#{selected_budget_id}/categories/#{category_id}")[:category]
  end

  def create_transaction(id: nil, payee_id: nil, payee_name: nil, amount: nil, cleared: nil, date: nil, memo: nil, flag: nil)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{selected_budget_id}/transactions", {
      transaction: {
        account_id: selected_account_id,
        date: date.to_s,
        amount: amount,
        payee_id: payee_id,
        payee_name: payee_name,
        cleared: cleared ? "Cleared" : 'Uncleared',
        memo: memo,
        flag_color: flag,
        import_id: id
      }
    }, {
      'Authorization' => "Bearer #{@access_token}"
    }))
  end

  def create_transactions(transactions)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{selected_budget_id}/transactions/bulk", {
      transactions: transactions.each{|d| d[:account_id] = selected_account_id }
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

  protected

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)[:data]
  end

end

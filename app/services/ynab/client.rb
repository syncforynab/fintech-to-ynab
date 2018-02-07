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

  def create_transaction(payee_id: nil, payee_name: nil, amount: nil, cleared: nil, date: nil, memo: nil, flag: nil)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{selected_budget_id}/transactions", {
      transaction: {
        account_id: selected_account_id,
        date: date.to_s,
        amount: amount,
        payee_id: payee_id,
        payee_name: payee_name,
        cleared: cleared ? "Cleared" : 'Uncleared',
        memo: memo,
        flag_color: flag
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

  def lookup_payee_id(payee_name)
    payees.select{|d| d[:name].downcase == payee_name.downcase  }.first.try(:[], :id)
  end

  def is_duplicate_transaction?(payee_id, date, amount)
    transactions.any? do |transaction|
      transaction[:date] == date.to_date.to_s &&
        transaction[:amount] == amount &&
        transaction[:payee_id] == payee_id
    end
  end

  protected

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)[:data]
  end

end

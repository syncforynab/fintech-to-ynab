class YNAB::Client

  BASE_URL = 'https://api.youneedabudget.com/papi/v1'

  def initialize(access_token, budget_id = nil, account_id = nil)
    @access_token = access_token
    @budget_id = budget_id || ENV['YNAB_BUDGET_ID']
    @account_id = account_id || ENV['YNAB_ACCOUNT_ID']
  end

  def budgets
    get('/budgets')[:budgets]
  end

  def accounts(budget_id)
    get("/budgets/#{budget_id}/accounts")[:accounts]
  end

  def categories(budget_id)
    get("/budgets/#{budget_id}/categories")
  end

  def payees(budget_id)
    get("/budgets/#{budget_id}/payees")[:payees]
  end

  def transactions(budget_id)
    get("/budgets/#{budget_id}/transactions")[:transactions]
  end

  def create_transaction(budget_id: nil, account_id: nil, payee_id: nil, payee_name: nil, category_id: nil, amount: nil, cleared: nil, date: nil, memo: nil)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{budget_id}/transactions", {
      transaction: {
        account_id: account_id,
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

  def create_transactions(budget_id, transactions)
    parse_response(RestClient.post(BASE_URL + "/budgets/#{budget_id}/transactions/bulk", {
      transactions: transactions
    }, {
      'Authorization' => "Bearer #{@access_token}"
    }))
  rescue => e
    raise JSON.parse(e.response.body).to_yaml
  end

  def get(url)
    parse_response(RestClient.get(BASE_URL + url, { 'Authorization' => "Bearer #{@access_token}" }))
  end

  def selected_budget_id
    @_selected_budget_id ||= @budget_id || budgets.first[:id]
  end

  def selected_account_id
    @_selected_account_id ||= @account_id || accounts(selected_budget_id).reject{|a| a[:closed]}.select{|a| a[:type] == 'Checking'}.first[:id]
  end

  def lookup_payee_id(payee_name)
    @_payee_names ||= payees(selected_budget_id).map {|p| { id: p[:id], name: p[:name] } }
    @_fuzzy_match ||= FuzzyMatch.new(@_payee_names, read: :name)

    payee_found = @_fuzzy_match.find(payee_name.to_s)
    payee_found = nil if payee_found.present? && payee_name.pair_distance_similar(payee_found[:name]) < 0.5
    payee_found.try(:[], :id)
  end

  protected

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)[:data]
  end

end

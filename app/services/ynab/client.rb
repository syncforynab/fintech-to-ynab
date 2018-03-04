class YNAB::Client

  def initialize(access_token, budget_id = nil, account_id = nil)
    @access_token = access_token
    @budget_id = budget_id || ENV['YNAB_BUDGET_ID']
    @account_id = account_id || ENV['YNAB_ACCOUNT_ID']
  end

  def budgets
    @_budgets ||= client.budgets.get_budgets.data.budgets
  end

  def accounts
    @_accounts ||= client.accounts.get_accounts(selected_budget_id).data.accounts
  end

  def transactions(since_date: nil)
    @transactions ||= client.transactions.get_transactions(selected_budget_id, since_date: since_date).data.transactions
  end

  def create_transaction(id: nil, payee_id: nil, payee_name: nil, amount: nil, cleared: nil, date: nil, memo: nil, flag: nil)
    client.transactions.create_transaction(selected_budget_id, {
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
    }).data.transaction
  rescue YnabApi::ApiError => e
    JSON.parse(e.response_body)
  end

  def create_transactions(transactions)
    client.transactions.bulk_create_transactions(selected_budget_id, { transactions: transactions }).data.bulk
  rescue YnabApi::ApiError => e
    JSON.parse(e.response_body)
  end

  def selected_budget_id
    @budget_id || budgets.first.id
  end

  def selected_account_id
   @account_id || accounts.reject{|a| a.closed}.select{|a| a.type == 'checking'}.first.id
  end

  protected

  def client
    @client ||= YnabApi::Client.new(@access_token)
  end
end

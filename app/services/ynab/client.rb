class YNAB::Client
  def initialize(access_token, budget_id = nil, account_id = nil)
    @access_token = access_token
    @budget_id = budget_id || ENV['YNAB_BUDGET_ID']
    @account_id = account_id
  end

  def budgets
    @_budgets ||= client.budgets.get_budgets.data.budgets
  end

  def accounts
    @_accounts ||= client.accounts.get_accounts(selected_budget_id).data.accounts
  end

  def category(category_id)
    client.categories.get_category_by_id(selected_budget_id, category_id).data.category
  end

  def transactions(since_date: nil, account_id: nil)
    if account_id.present?
      client.transactions.get_transactions_by_account(selected_budget_id, account_id, since_date: since_date).data.transactions
    else
      client.transactions.get_transactions(selected_budget_id, since_date: since_date).data.transactions
    end
  end

  def update_transaction(transaction_id, transaction)
    client.transactions.update_transaction(selected_budget_id, transaction_id, {
      transaction: {
        account_id: selected_account_id,
        date: transaction[:date].to_s,
        amount: transaction[:amount],
        payee_id: transaction[:payee_id],
        payee_name: transaction[:payee_name],
        cleared: transaction[:cleared] ? "Cleared" : 'Uncleared',
        memo: transaction[:description],
        flag_color: transaction[:flag],
        import_id: transaction[:id]
      }
    }).data.transaction
  rescue => e
    Rails.logger.error('YNAB::Client.update_transaction failure')
    Rails.logger.error("YNAB::Client.update_transaction Response: #{e.response_body}")
    Rails.logger.error(e)
    false
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
  rescue => e
    Rails.logger.error('YNAB::Client.create_transaction failure')
    Rails.logger.error("YNAB::Client.create_transaction Response: #{e.response_body}")
    Rails.logger.error(e)
    false
  end

  def create_transactions(transactions)
    client.transactions.bulk_create_transactions(selected_budget_id, { transactions: transactions }).data.bulk
  rescue => e
    Rails.logger.error('YNAB::Client.create_transactions failure')
    Rails.logger.error("YNAB::Client.create_transactions Request Body: #{transactions}")
    Rails.logger.error("YNAB::Client.create_transactions Response: #{e.response_body}")
    Rails.logger.error(e)
    false
  end

  def selected_budget_id
    @budget_id || budgets.first.id
  end

  def selected_account_id
    @account_id || accounts.reject(&:closed).select { |a| a.type == 'checking' }.first.id
  end

  protected

  def client
    @client ||= YnabApi::Client.new(@access_token)
  end
end

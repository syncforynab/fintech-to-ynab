class Import::Starling
  def initialize(access_token, ynab_account_id, from: nil)
    @starling = Starling::Client.new(access_token: access_token)
    @ynab_account_id = ynab_account_id
    @from = from
  end

  def import
    from = (@from || @starling.account.get.created_at).to_date
    transactions_to_create = []
    @starling.transactions.list(params: { from: from, to: Date.today }).each do |transaction|
      transactions_to_create << {
        amount: (transaction.amount * 1000).to_i,
        payee_name: transaction.narrative.strip,
        date: transaction.created,
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end
end

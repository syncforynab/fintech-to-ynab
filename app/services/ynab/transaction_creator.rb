class YNAB::TransactionCreator
  def initialize(id: nil, date: nil, amount: nil, payee_name: nil, description: true, flag: nil, cleared: true, budget_id: nil, account_id: nil)
    @id = id
    @date = date
    @amount = amount
    @payee_name = payee_name
    @description = description
    @cleared = cleared
    @flag = flag

    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
    @import_id_creator = YNAB::ImportIdCreator.new
  end

  def create
    Rails.logger.info("Prefilling import ids")
    @import_id_creator.prefill!(@client, @date.to_date)

    create = @client.create_transaction(
      id: @import_id_creator.import_id(@amount, @date.to_date),
      payee_name: @payee_name,
      amount: @amount,
      cleared: @cleared,
      date: @date.to_date,
      memo: @description,
      flag: @flag
    )

    create.try(:id).present? ? create : { error: :failed, data: create }
  end
end

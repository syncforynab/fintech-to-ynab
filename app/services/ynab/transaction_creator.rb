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
  end

  def create
    create = @client.create_transaction(
      id: @id.to_s.truncate(36),
      payee_name: @payee_name.to_s.truncate(50),
      amount: @amount,
      cleared: @cleared,
      date: @date.to_date,
      memo: @description,
      flag: @flag
    )

    # If the transaction has a category, then lets notify
    if create.try(:category_id).present?
      begin
        ynab_category = @client.category(create.category_id)
        notifier = CategoryBalanceNotifier.new
        notifier.discover_services
        notifier.notify(ynab_category)
      rescue => e
        Rails.logger.error('Category Balance Notifier Failed')
        Rails.logger.error(e)
      end
    end

    create.try(:id).present? ? create : { error: :failed, data: create }
  end
end

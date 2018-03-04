class YNAB::BulkTransactionCreator

  BATCH_SIZE = 20.freeze

  def initialize(transactions, budget_id: nil, account_id: nil)
    @transactions = transactions
    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
    @import_id_creator = YNAB::ImportIdCreator.new
  end

  def create
    if @transactions.size == 0
      Rails.logger.info(:no_transactions_to_create)
      return false
    end

    batches = (@transactions.size.to_f / BATCH_SIZE).ceil
    per_batch = @transactions.size / batches

    Rails.logger.info("Splitting #{@transactions.size} transactions into #{batches} batches")

    @transactions.each_slice(BATCH_SIZE).with_index do |transactions, index|
      Rails.logger.info("Processing batch #{index + 1} of #{batches}")

      transactions_to_create = []
      transactions.each do |transaction|

        transactions_to_create << {
          import_id: @import_id_creator.import_id(transaction[:amount], transaction[:date].to_date),
          account_id: @client.selected_account_id,
          payee_name: transaction[:payee_name],
          amount: transaction[:amount],
          memo: transaction[:description],
          date: transaction[:date].to_date,
          cleared: !!transaction[:cleared] ? 'Cleared' : 'Uncleared',
          flag: transaction[:flag]
        }
      end

      if transactions_to_create.any?
        begin
          Rails.logger.info(@client.create_transactions(transactions_to_create))
        rescue => e
          Rails.logger.error(e.response.body)
        end
      else
        Rails.logger.info(:no_transactions_to_create)
      end
    end
  end
end

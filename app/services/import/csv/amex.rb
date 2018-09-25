require 'csv'

# @note This is used to import Amex CSV Statements
# Export the statement CSV from within the web app

class Import::Csv::Amex
  def initialize(path, ynab_account_id = ENV['YNAB_AMEX_ACCOUNT_ID'])
    @path = path
    @ynab_account_id = ynab_account_id
    @import_id_creator = YNAB::ImportIdCreator.new
  end

  def import
    transactions_to_create = []

    ::CSV.foreach(@path) do |transaction|
      amount = (transaction[1].to_f * 1000).to_i
      date = Date.parse(transaction[0])

      transactions_to_create << {
        id: @import_id_creator.import_id(amount, date),
        amount: amount,
        payee_name: transaction[2],
        date: date,
        description: transaction[2]
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end
end

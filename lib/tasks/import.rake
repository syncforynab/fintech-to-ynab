namespace :import do
  desc 'Imports transactions from your Monzo account'
  task :monzo => :environment do
    # Configure these environment variables on your Heroku instance
    monzo_access_token = ENV.fetch('MONZO_ACCESS_TOKEN')
    monzo_account_id = ENV.fetch('MONZO_ACCOUNT_ID')
    ynab_account_id = ENV.fetch('YNAB_MONZO_ACCOUNT_ID')
    from_date = Date.parse(ENV['from_date']) rescue 1.year.ago

    begin
      puts "Importing transactions since #{from_date.to_formatted_s(:medium)}."
      Import::Monzo.new(monzo_access_token, monzo_account_id, ynab_account_id, from: from_date).import
    rescue StandardError => e
      puts "Monzo import failed (#{e}). Check your environment variables are correct."
      exit 1
    end
  end
end

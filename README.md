# Mondo to YNAB

Automatically push Mondo transactions to YNAB

## Notes
 - Category will be blank
  - This is partially because we cannot be sure what categories you have in YNAB and also because totally automating this will reduce your visibility of your money

## Deployment notes
 - Personally using Dokku to host this. Heroku should be easy too
 - Set Environment Variables (See below)
 - Remember to register your webhook URL. You can do it here: https://developers.getmondo.co.uk/

## Environment Variables
 - LOG_LEVEL=debug
 - YNAB_ACCOUNT=Mondo
 - YNAB_BUDGET=Testing Mondo
 - YNAB_USERNAME=
 - YNAB_PASSWORD=

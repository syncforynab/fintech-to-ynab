# Mondo to YNAB

Automatically push Mondo transactions to YNAB using https://github.com/rienafairefr/nYNABapi

A huge thanks to @rienafairefr for the nYNAB library

## Notes
 - I don't know much python, so excuse the horrible code
 - Because there is no official API for YNAB, this could break at any point (submit an issue)
 - Category will be blank in YNAB

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

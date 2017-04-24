# Mondo to YNAB

Automatically push Mondo transactions to YNAB using https://github.com/rienafairefr/nYNABapi

A huge thanks to @rienafairefr for the nYNAB library

## Notes
 - Deuplication code is currently glitched. If you purchase from the same company twice in one day we will not enter the second transaction. This is due to the bug with pynynab. Hopefully this will be resolved quickly. I'm not going to push to docker until this is fixed.
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

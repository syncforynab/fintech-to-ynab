# Mondo to YNAB

Automatically push Monzo transactions into YNAB.

A huge thanks to [@rienafairefr](https://github.com/rienafairefr/nYNABapi) for the YNAB library.

## Notes
 - I don't know much python, so excuse the horrible code
 - Because there is no official API for YNAB, this could break at any point (submit an issue)
 - Category will be blank in YNAB

## Deployment notes
 - Setup the environment variables
 - Register your webhook URL. You can do it here: https://developers.monzo.com/

## Environment Variables

Either set the environment variables from `.env.example` or copy that file to `.env`

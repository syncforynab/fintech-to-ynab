# Mondo to YNAB

Automatically push Monzo transactions into YNAB.

A huge thanks to [@rienafairefr](https://github.com/rienafairefr/nYNABapi) for the YNAB library.

## Notes
 - Deuplication code is currently glitched. If you purchase from the same company twice in one day we will not enter the second transaction. This is due to the bug with pynynab. Hopefully this will be resolved quickly. I'm not going to push to docker until this is fixed.
 - I don't know much python, so excuse the horrible code
 - Because there is no official API for YNAB, this could break at any point (submit an issue)
 - Category will be blank in YNAB

## Deployment notes
 - Setup the environment variables
 - Register your webhook URL. You can do it here: https://developers.monzo.com/

## Environment Variables

Either set the environment variables from `.env.example` or copy that file to `.env`

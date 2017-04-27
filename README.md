# Monzo to YNAB

[![Docker Build Statu](https://img.shields.io/docker/build/scottrobertson/monzo-to-ynab.svg)](https://hub.docker.com/r/scottrobertson/monzo-to-ynab/)


[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/scottrobertson/monzo-to-ynab)

Automatically push Monzo transactions into YNAB.

A huge thanks to [@rienafairefr](https://github.com/rienafairefr/nYNABapi) for the YNAB library.

## Features
  - Push your Monzo transactions into YNAB in realtime
  - Automatically populate the category based on previous transactions
  - Add emoji and hashtags to your YNAB transactions by default (can be disabled)
  - Automatically mark transactions as cleared (except for those in a foreign currency)

## Deployment notes

Please see our [Deployment](https://github.com/scottrobertson/monzo-to-ynab/wiki/Deployment) wiki for instructions on how to deploy this app.

## Environment Variables

Either set the environment variables from `.env.example` or copy that file to `.env`

**Warning**: Because there is no official API for YNAB, this could break at any point

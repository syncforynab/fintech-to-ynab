# Fintech to YNAB

[![Docker](https://img.shields.io/docker/build/scottrobertson/fintech-to-ynab.svg)](https://hub.docker.com/r/scottrobertson/fintech-to-ynab/)
[![CircleCI](https://img.shields.io/circleci/project/github/scottrobertson/fintech-to-ynab.svg)]()
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/scottrobertson/fintech-to-ynab)

Automatically push Monzo and Starling transactions into YNAB.

A huge thanks to [@rienafairefr](https://github.com/rienafairefr/nYNABapi) for the YNAB library.

## Features
  - Push your Monzo and Starling transactions into YNAB in realtime
  - Automatically populate the category based on previous transactions
  - Add 😃 🍏 emoji ✈️ 🇨🇦 and #hashtags to your YNAB transactions by default (can be disabled, Monzo only)
  - Automatically mark transactions as cleared (except for those in a foreign currency, Monzo only)

## Deployment notes

Please see our [Deployment](https://github.com/scottrobertson/fintech-to-ynab/wiki/Deployment) wiki for instructions on how to deploy this app.

## Environment Variables

Either set the environment variables from `.env.example` or copy that file to `.env`

**Warning**: Because there is no official API for YNAB, this could break at any point

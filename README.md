# Fintech to YNAB

[![Docker](https://img.shields.io/docker/build/scottrobertson/fintech-to-ynab.svg)](https://hub.docker.com/r/scottrobertson/fintech-to-ynab/)
[![CircleCI](https://img.shields.io/circleci/project/github/scottrobertson/fintech-to-ynab.svg)](https://circleci.com/gh/scottrobertson/fintech-to-ynab)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/scottrobertson/fintech-to-ynab)

Automatically push Monzo and Starling transactions into YNAB.

A huge thanks to [@rienafairefr](https://github.com/rienafairefr/nYNABapi) for the YNAB library.

> **Note Starling support is pending support for [Personal Access Webhooks](https://trello.com/c/rviKbwNQ/47-personal-access-webhooks-%F0%9F%93%AF).**

## Features
  - Push your Monzo and Starling transactions into YNAB in realtime
  - Automatically populate the category based on previous transactions
  - Add 😃 🍏 emoji ✈️ 🇨🇦 and #hashtags to your YNAB transactions by default (can be disabled, Monzo only)
  - Automatically mark transactions as cleared (except for those in a foreign currency, Monzo only)
  - Import CSV directly into YNAB

## Getting Started

Please see our [Getting Started](https://github.com/scottrobertson/fintech-to-ynab/wiki/Getting-Started) guide to see how to set Fintech to YNAB up.

## CSV Imports

You can import a CSV directly into YNAB via the CLI. To do so, please use the following:

```
python python/import.py --account=AccountName --path=/path/to.csv
```

The format should be: date, description, amount

**Warning**: This app is not officially supported by YNAB in any way. Use of this app could introduce problems into your budget that YNAB, through its official support channels, will not be able to troubleshoot or fix. Please use at your own risk!

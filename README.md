# Fintech to YNAB

[![Docker](https://img.shields.io/docker/build/fintechtoynab/fintech-to-ynab.svg)](https://hub.docker.com/r/fintechtoynab/fintech-to-ynab)


[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/fintech-to-ynab/fintech-to-ynab)

> **This version requires beta access to the [YNAB API](https://api.youneedabudget.com/), please use the [v1 branch](https://github.com/scottrobertson/fintech-to-ynab/tree/v1) if you do not have access**

Automatically push Monzo transactions to YNAB in realtime. Also import historical transactions for many more banks.

## Features
  - Push your Monzo transactions into YNAB in realtime
  - Automatically populate the category based on previous transactions
  - Add 😃 🍏 emoji ✈️ 🇨🇦 and #hashtags to your YNAB transactions by default
  - Automatically mark transactions as cleared (except for those in a foreign currency)
  - Import your bank history using [Imports](#imports)

## Getting Started

Please see our [Getting Started](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/Getting-Started) guide to see how to set Fintech to YNAB up.

## Imports

As well as real-time webhooks, we also support bulk imports for the following financial institutions:

- [CSV](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/Import:-CSV)
- [Monzo](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Monzo)
- [Starling](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Starling-Bank)
- [Barclays](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Isle of Man Bank](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Metro Bank](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Nationwide](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Natwest](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Royal Bank of Scotland](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Santander](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Tesco](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [TSB](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [Ulster Bank NI](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)
- [HSBC UK](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/import:-Teller)

> This app is not officially supported by YNAB in any way. Use of this app could introduce problems into your budget that YNAB, through its official support channels, will not be able to troubleshoot or fix. Please use at your own risk!

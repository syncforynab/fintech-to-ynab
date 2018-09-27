# Fintech to YNAB

[![Docker](https://img.shields.io/docker/build/fintechtoynab/fintech-to-ynab.svg)](https://hub.docker.com/r/fintechtoynab/fintech-to-ynab)
[![CircleCI](https://circleci.com/gh/fintech-to-ynab/fintech-to-ynab.svg?style=svg)](https://circleci.com/gh/fintech-to-ynab/fintech-to-ynab)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/fintech-to-ynab/fintech-to-ynab)

Automatically push Monzo and Starling transactions to YNAB in realtime. Also import historical transactions from Barclays, Revolut Business, Nationwide, Natwest and many more banks.

## Features
  - Push your Monzo and Starling transactions into YNAB in realtime
  - Automatically populate the category based on previous transactions
  - Add 😃 🍏 emoji ✈️ 🇨🇦 and #hashtags to your YNAB transactions by default (for Monzo)
  - Automatically mark transactions as cleared (except for those in a foreign currency)
  - Import your bank history using [Imports](#imports)

## Getting Started

Please see our [Getting Started](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/Getting-Started) guide to see how to set Fintech to YNAB up.

## Banks/Financial Institutions

As well as real-time webhooks, we also support bulk/historical imports for the following financial institutions:

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
- [MBNA](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/Import:-CSV)
- [Amex](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/Import:-CSV)
- [Revolut Business](https://github.com/fintech-to-ynab/fintech-to-ynab/wiki/Import:-Revolut-Business)

*To request a new Bank/Financial Institution, please comment [here](https://github.com/fintech-to-ynab/fintech-to-ynab/issues/73).*

> This app is not officially supported by YNAB in any way. Use of this app could introduce problems into your budget that YNAB, through its official support channels, will not be able to troubleshoot or fix. Please use at your own risk!

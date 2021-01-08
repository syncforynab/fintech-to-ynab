# Fintech to YNAB

![Docker](https://github.com/syncforynab/fintech-to-ynab/workflows/Docker/badge.svg)
![Tests](https://github.com/syncforynab/fintech-to-ynab/workflows/Tests/badge.svg)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/syncforynab/fintech-to-ynab)

Automatically push Monzo and Starling transactions to YNAB in realtime, plus import historical transactions.

## syncforynab.com

I have launched [syncforynab.com](https://syncforynab.com), a fully hosted version of Fintech to YNAB with support for American Express, Bank of Scotland, Barclaycard, Barclays, Barclays Business, Danske, first direct, Halifax, HSBC, HSBC Business, Lloyds, Lloyds Business, M&S Bank, MBNA, Monzo, Nationwide, NatWest, RBS, Revolut, Santander, Starling, TSB & Ulster Bank with more coming all the time. It also supports generic CSV uploads from any bank.

## Features

- Push your Monzo and Starling transactions into YNAB in realtime
- Automatically populate the category based on previous transactions
- Add 😃 🍏 emoji ✈️ 🇨🇦 and #hashtags to your YNAB transactions by default (for Monzo)
- Automatically mark transactions as cleared (except for those in a foreign currency)
- Import your bank history using [Imports](#imports)

## Getting Started

Please see our [Getting Started](https://github.com/syncforynab/fintech-to-ynab/wiki/Getting-Started) guide to see how to set Fintech to YNAB up.

## Banks/Financial Institutions

As well as real-time webhooks, we also support bulk/historical imports for the following financial institutions:

- [CSV](https://github.com/syncforynab/fintech-to-ynab/wiki/Import:-CSV)
- [Monzo](https://github.com/syncforynab/fintech-to-ynab/wiki/import:-Monzo)
- [Starling](https://github.com/syncforynab/fintech-to-ynab/wiki/import:-Starling-Bank)

_To request a new Bank/Financial Institution, please comment [here](https://github.com/fintech-to-ynab/fintech-to-ynab/issues/73)._

> This app is not officially supported by YNAB in any way. Use of this app could introduce problems into your budget that YNAB, through its official support channels, will not be able to troubleshoot or fix. Please use at your own risk!

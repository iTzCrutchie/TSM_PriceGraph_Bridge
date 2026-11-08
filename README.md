# TSM Price Graph Bridge

A lightweight compatibility addon that connects **TradeSkillMaster (TSM)** to **Auction Price Graph** without needing to manually maintain duplicate shopping lists in Auctionator.

Auction Price Graph relies on Auctionator's shopping list structure and database format to render item price histories. If you use TSM for all of your group management and scans, this bridge automatically mirrors your TSM groups into Auctionator's list format and seeds the graph database using your existing TSM price data.

## Features

* **Automatic Group Sync:** Reads your existing TSM group hierarchy on login and creates matching `TSM: [Group Name]` shopping lists that Auction Price Graph can read natively.
* **Historical Price Backfill:** Seeds empty item graphs with your local TSM `dbhistorical`, `dbmarket`, and `minbuyout` values so lines render immediately without waiting days for manual scans.
* **Non-Destructive:** Works alongside standard CurseForge installations of Auctionator and Auction Price Graph. No manual `.toc` edits or core addon modifications required.

## Requirements

All three base addons must be enabled so dependencies resolve properly:
1. [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskillmaster) (v4.14+)
2. [Auctionator](https://www.curseforge.com/wow/addons/auctionator)
3. [Auction Price Graph](https://www.curseforge.com/wow/addons/auction-price-graph)

## Installation

1. Download the latest release or clone this repository.
2. Copy the `TSM_PriceGraph_Bridge` folder into your World of Warcraft `Interface/AddOns/` directory.
3. Restart your WoW client or run `/reload` in-game.

## How It Works

Two seconds after `PLAYER_LOGIN` fires (allowing TSM and the item cache to finish initializing), the addon:
1. Queries `TSM_API.GetGroupPaths` and `TSM_API.GetGroupItems` to build a list of all items across your TSM groups.
2. Injects those items into Auctionator's `ListManager` (and legacy `AUCTIONATOR_SHOPPING_LISTS` table) prefixed with `TSM: `.
3. Checks `AuctionPriceGraphDB` for any grouped items with fewer than two recorded data points and populates a 48-hour baseline using TSM's internal price sources.

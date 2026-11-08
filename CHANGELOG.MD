# Changelog

All notable changes to this project will be documented in this file.

## [0.0.1] - 2026-11-08

### Added
- Initial release of `TSM_PriceGraph_Bridge`.
- Automatic synchronization of TSM group paths and items into Auctionator shopping lists (`TSM: [Group Path]`) on `PLAYER_LOGIN`.
- Historical price backfilling into `AuctionPriceGraphDB` using TSM's `dbhistorical`, `dbmarket`, and `minbuyout` sources so new items plot immediately.
- Delayed initialization timer (`C_Timer.After`) to ensure TSM4 internal tables and item caches are warm before querying group items.
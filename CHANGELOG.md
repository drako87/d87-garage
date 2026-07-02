# Changelog

All notable changes to this project are documented here.

## [1.0.1] - Bugfix release

### Fixed
- **NUI black background around the garage menu.** The Google Fonts and
  FontAwesome `<link rel="stylesheet">` tags were render-blocking, so if that
  CDN was slow or unreachable from the client, the CEF browser could never
  complete its first paint and fell back to a solid black frame instead of
  the transparent one defined in `style.css`. Fonts/icons now load
  asynchronously (`preload` + swap on load) and an inline `<style>` block
  forces `background: transparent` before anything else is parsed, so the
  NUI is guaranteed transparent immediately regardless of network state.
- **`NETWORK_GET_NETWORK_ID_FROM_ENTITY: no such entity`, `GetNetworkObject:
  no object by ID 0` and `GET_VEHICLE_FUEL_LEVEL: No such entity` warnings
  when storing a vehicle.** The server was deleting the vehicle entity
  immediately after the DB write while the player was, in almost all cases,
  still sitting in the driver's seat (they had just driven up to the entry
  marker). Deleting a networked vehicle out from under its driver is what
  produced the warnings and could glitch the ped. The client now safely
  tasks the driver out of the vehicle (with a brief freeze so it doesn't
  roll away) *before* it ever asks the server to delete it.
- `Bridge.DeleteVehicle` on the Qbox (`qbx`) branch could be called on an
  entity that no longer existed; it's now guarded with `DoesEntityExist`
  like the other framework branches.
- The server now re-checks `DoesEntityExist` right before deleting a parked
  vehicle, since the DB writes it waits on are async and take a moment.

### Added
- **Server-side spawn point clearance check.** `Config.vehicle.distanceCheck`
  existed in the config and had a matching `error.no_space` locale string,
  but nothing ever used them — vehicles could spawn stacked on top of each
  other. It's now enforced before every spawn.
- **Server-side distance validation for "Take Out".**
  `Config.vehicle.spawnDistanceCheck` was likewise defined but unused. The
  server now verifies the player is actually near the garage before
  honouring a spawn request, closing an exploit-menu vector where the
  callback could otherwise be triggered from anywhere on the map.
- **Spawn lock per player**, so double-clicking "Take Out" (or a laggy
  click) can no longer create two copies of the same vehicle. Uses the
  previously-unused `error.spawn_in_progress` locale string.
- Vehicle spawn failures are now reported with the localized
  `error.spawn_failed` message instead of a hardcoded English string.
- Locale files are now fully synced: every one of the 19 languages has the
  same 28 keys (several were missing `no_space`, `spawn_failed`,
  `spawn_in_progress`, `pay_impound`, `search`, `status_out`,
  `status_garaged`, `status_impounded` and `info.spawning`, which meant the
  UI silently fell back to English text for those strings).

### Changed
- Bumped resource version to `1.0.1`.

---

## [1.0.0] - Initial release

- Multi-framework support (QBCore, Qbox, ESX, Standalone).
- 3-zone garage layout (menu / entry / exit).
- Glassmorphism NUI with live search, damage/fuel bars and status badges.
- Impound/depot system with configurable base fee or % of vehicle price.
- Job/gang-restricted garages.

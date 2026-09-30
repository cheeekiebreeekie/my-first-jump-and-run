# Changelog
## [v0.0.4] - 01.09.2026

### Added
- Safety checks in dampening calculations
- Additional code comments
- CHANGELOG.md
- README.md
- LICENSE.txt

### Changed
- Drag equation now uses `velocity * velocity.length()` instead of `velocity.normalized() * velocity.length_squared()`
- sign() of gravity in dampening stiffness calculation
- Removed unused variables
- Changed main.tscn layout

### Fixed
- Critical game crash when gravity turned negative
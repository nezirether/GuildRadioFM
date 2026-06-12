GuildRadioFM Versioning

GuildRadioFM uses Semantic Versioning.

The format is:

MAJOR.MINOR.PATCH

Example:

0.6.0

Major Version

The first number is the major version.

GuildRadioFM will stay in major version 0 while the product is still being built.

GuildRadioFM should only become v1.0.0 when it feels like a complete public product.

Minor Version

The second number is the minor version.

Increase this number when GuildRadioFM adds a new user-facing feature or roadmap milestone.

Examples:

- v0.4.0 Queue System
- v0.5.0 Seek Controls
- v0.6.0 Sharing and Broadcast Requests
- v0.6.0 Broadcast Requests
- v0.7.0 Party Sync Framework

Patch Version

The third number is the patch version.

Increase this number for fixes and small polish work that do not add a major new system.

Examples:

- v0.4.1 Queue bug fix
- v0.4.2 Queue UI polish
- v0.5.1 Seek Controls typo fix
- v0.6.1 Sharing bug fix

Historical Migration

Older GuildRadioFM builds used larger early development version numbers. The project now uses simpler pre-1.0 semantic versions.

- v2.1.2 Hidden Frequency Vol. 1 is now treated as v0.2.0
- v2.2.0 Lyrics Polish is now treated as v0.3.0
- v2.3.0 Queue System is now v0.4.0

Single Source Of Truth

The Lua source of truth is:

GuildRadioFM.Version

The addon TOC version, README, changelog, and UI labels should match that value for each release.

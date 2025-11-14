# NS8-Nextcloud: Summary of Open Pull Requests

This document summarizes the currently open pull requests for the ns8-nextcloud module, with particular emphasis on the major upgrade to Nextcloud version 32.

## 🚀 MAJOR HIGHLIGHT: Nextcloud 32 Upgrade

Two pull requests are proposing the major upgrade to Nextcloud version 32:

### PR #167: Update nextcloud docker tag to v32
- **Type**: Major version upgrade (automated by Renovate)
- **Change**: Upgrades Nextcloud from `31.0.7-fpm-alpine` to `32.0.1-fpm-alpine`
- **Status**: Open, mergeable
- **Link**: https://github.com/NethServer/ns8-nextcloud/pull/167
- **Description**: This PR updates the Nextcloud Docker image to version 32, which represents a major version jump from version 31.

### PR #158: Update docker.io/library/nextcloud docker tag to v32
- **Type**: Major version upgrade (automated by Renovate)
- **Change**: Upgrades Nextcloud from `31.0.7-fpm-alpine` to `32.0.1-fpm-alpine`
- **Status**: Open
- **Created**: September 30, 2025
- **Link**: https://github.com/NethServer/ns8-nextcloud/pull/158
- **Description**: Similar to PR #167, this PR also proposes upgrading to Nextcloud version 32.

**Note**: These two PRs appear to be duplicate upgrade proposals. The team should decide which one to merge.

## 📦 Related Component Updates

### PR #156: Update nextcloud/notify_push to v1.2.1
- **Type**: Minor dependency update
- **Change**: Updates notify_push from `1.1.1` to `1.2.1`
- **Status**: Open, mergeable
- **Link**: https://github.com/NethServer/ns8-nextcloud/pull/156
- **Relevance**: The v1.2.0 release of notify_push specifically mentions **compatibility with Nextcloud 32**, making this update important for the version 32 upgrade
- **Key Features**:
  - Compatible with Nextcloud 32
  - Bug fixes and improvements for the push notification service

## 🔧 Feature and Enhancement PRs

### PR #168: Set org.nethserver.volumes label
- **Type**: Feature enhancement
- **Change**: Adds volume label for better disk management
- **Status**: Open, mergeable
- **Link**: https://github.com/NethServer/ns8-nextcloud/pull/168
- **Reference**: NethServer/dev#7665
- **Description**: Suggests the `nextcloud-app-data` volume to be located on an additional disk for improved storage management
- **Impact**: 1 file changed, 1 addition

### PR #160: Enhance Nextcloud configuration and Traefik integration
- **Type**: Configuration improvements
- **Status**: Open (merge conflicts present)
- **Link**: https://github.com/NethServer/ns8-nextcloud/pull/160
- **Reference**: https://github.com/NethServer/dev/issues/7669
- **Description**: Comprehensive improvements including:
  - Improved Nextcloud and Traefik configuration scripts
  - Addition of Let's Encrypt status notifications
  - Enhanced error handling
  - Better routing configuration
  - Default values for Let's Encrypt in restore-module script
  - Updated build labels to reflect core version
- **Impact**: 22 commits, 8 files changed, 185 additions, 132 deletions
- **Note**: This PR requires rebase due to merge conflicts

### PR #147: Update MariaDB docker tag to v10.6.24
- **Type**: Patch update for database
- **Change**: Updates MariaDB from `10.6.22` to `10.6.24`
- **Status**: Open, mergeable (but tests unstable)
- **Link**: https://github.com/NethServer/ns8-nextcloud/pull/147
- **Description**: Routine patch update for the MariaDB database component

## 🎯 Recommendation

The most critical action items are:

1. **Prioritize the Nextcloud 32 upgrade**: Choose and merge either PR #167 or #158 (they appear to be duplicates)
2. **Merge PR #156 (notify_push v1.2.1)**: This is essential for Nextcloud 32 compatibility
3. **Address PR #160**: Resolve merge conflicts and review the configuration enhancements
4. **Evaluate PR #168**: Simple but useful feature for disk management
5. **Consider PR #147**: MariaDB patch update for security and stability

## ⚠️ Note on Excluded PRs

As per instructions, the following PRs were excluded from this summary:
- PR #132: chore(deps): update ghcr.io/marketsquare/robotframework-browser/rfbrowser-stable docker tag to v19.10.1
- PR #155: chore(deps): update docker.io/library/nextcloud docker tag to v31.0.10
- PR #166: chore(deps): update nextcloud docker tag to v31.0.10

---

**Repository**: NethServer/ns8-nextcloud  
**Summary Generated**: November 14, 2025  
**Total Active PRs**: 10 (7 summarized above, 3 excluded per instructions)

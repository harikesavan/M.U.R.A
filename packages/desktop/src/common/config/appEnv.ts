/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import { getPlatformServices } from '@/common/platform';

/**
 * Returns baseName unchanged in release builds, or baseName + '-dev' in dev builds.
 * When MURA_MULTI_INSTANCE=1, appends '-2' to isolate the second dev instance.
 * Used to isolate symlink and directory names between environments.
 *
 * @example
 * getEnvAwareName('.mura')        // release → '.mura',        dev → '.mura-dev'
 * getEnvAwareName('.mura-config') // release → '.mura-config', dev → '.mura-config-dev'
 * // with MURA_MULTI_INSTANCE=1:  dev → '.mura-dev-2'
 */
export function getEnvAwareName(baseName: string): string {
  if (getPlatformServices().paths.isPackaged() === true) return baseName;
  const suffix = process.env.MURA_MULTI_INSTANCE === '1' ? '-dev-2' : '-dev';
  return `${baseName}${suffix}`;
}

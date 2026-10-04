/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useEffect, useState } from 'react';
import muraArtwork from '@/renderer/assets/logos/brand/mura-presence.png';
import styles from './MuraPresence.module.css';

export type MuraPresenceProps = {
  size?: number;
  compact?: boolean;
  className?: string;
};

const MuraPresence: React.FC<MuraPresenceProps> = ({ size = 160, compact = false, className }) => {
  const [paused, setPaused] = useState<boolean>(() => typeof document !== 'undefined' && document.hidden);

  useEffect(() => {
    const onVisibility = () => setPaused(document.hidden);
    document.addEventListener('visibilitychange', onVisibility);
    return () => document.removeEventListener('visibilitychange', onVisibility);
  }, []);

  const dimension = compact ? 40 : size;

  return (
    <div
      className={[styles.presence, compact ? styles.compact : '', paused ? styles.paused : '', className ?? ''].filter(Boolean).join(' ')}
      style={{ width: dimension, height: dimension }}
      role='img'
      aria-label='Mura'
    >
      <img className={styles.artwork} src={muraArtwork} alt='' aria-hidden='true' draggable={false} />
    </div>
  );
};

export default MuraPresence;

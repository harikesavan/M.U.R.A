/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import { Waves, ListCheckbox, Search } from '@icon-park/react';
import React from 'react';
import { useTranslation } from 'react-i18next';
import styles from './GuidStarterActions.module.css';

export type StarterKey = 'untangle' | 'plan' | 'research';

export type GuidStarterActionsProps = {
  onSelect: (prompt: string) => void;
};

const STARTERS: ReadonlyArray<{ key: StarterKey; labelKey: string; promptKey: string; Icon: typeof Waves }> = [
  { key: 'untangle', labelKey: 'guid.startPage.starters.untangle', promptKey: 'guid.startPage.starterPrompts.untangle', Icon: Waves },
  { key: 'plan', labelKey: 'guid.startPage.starters.plan', promptKey: 'guid.startPage.starterPrompts.plan', Icon: ListCheckbox },
  { key: 'research', labelKey: 'guid.startPage.starters.research', promptKey: 'guid.startPage.starterPrompts.research', Icon: Search },
];

const GuidStarterActions: React.FC<GuidStarterActionsProps> = ({ onSelect }) => {
  const { t } = useTranslation();

  return (
    <div className={styles.row}>
      {STARTERS.map(({ key, labelKey, promptKey, Icon }) => (
        <button key={key} type='button' className={styles.chip} onClick={() => onSelect(t(promptKey))}>
          <Icon theme='outline' size='16' className={styles.icon} />
          <span className={styles.label}>{t(labelKey)}</span>
        </button>
      ))}
    </div>
  );
};

export default GuidStarterActions;

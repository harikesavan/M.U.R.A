/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import { FileText, Right } from '@icon-park/react';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import type { TChatConversation } from '@/common/config/storage';
import { useConversationHistoryContext } from '@/renderer/hooks/context/ConversationHistoryContext';
import styles from './GuidResumeEntry.module.css';

function findMostRecentConversation(
  pinned: TChatConversation[],
  sections: ReturnType<typeof useConversationHistoryContext>['groupedHistory']['timelineSections']
): TChatConversation | null {
  if (pinned.length > 0) return pinned[0];
  for (const section of sections) {
    for (const item of section.items) {
      if (item.type === 'conversation' && item.conversation) return item.conversation;
    }
  }
  return null;
}

const GuidResumeEntry: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { groupedHistory } = useConversationHistoryContext();

  const recent = useMemo(
    () => findMostRecentConversation(groupedHistory.pinnedConversations, groupedHistory.timelineSections),
    [groupedHistory.pinnedConversations, groupedHistory.timelineSections]
  );

  if (!recent) return null;

  return (
    <button type='button' className={styles.entry} onClick={() => void navigate(`/conversation/${recent.id}`)}>
      <div className={styles.left}>
        <span className={styles.resumeLabel}>{t('guid.startPage.resumeLabel')}</span>
        <span className={styles.title}>
          <FileText theme='outline' size='16' className={styles.fileIcon} />
          {recent.name}
        </span>
      </div>
      <Right theme='outline' size='18' className={styles.chevron} />
    </button>
  );
};

export default GuidResumeEntry;

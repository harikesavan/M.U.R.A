/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import { FileText, ListCheckbox, Right, Search, Waves } from '@icon-park/react';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import useSWR from 'swr';
import type { TChatConversation } from '@/common/config/storage';
import { requestConversationSendBoxPrefill } from '@/renderer/hooks/chat/useSendBoxDraft';
import { useConversationHistoryContext } from '@/renderer/hooks/context/ConversationHistoryContext';
import { getConversationOrNull } from '@/renderer/pages/conversation/utils/conversationCache';
import MuraPresence from '@/renderer/pages/guid/components/MuraPresence';
import styles from './SingleChatEmptyState.module.css';

type Props = {
  conversation_id: string;
  assistant_name?: string;
  assistant_backend?: string;
  icon?: string;
};

const findMostRecentOther = (conversations: TChatConversation[], currentId: string): TChatConversation | null => {
  let best: TChatConversation | null = null;
  for (const conversation of conversations) {
    if (conversation.id === currentId) continue;
    if (!best || (conversation.modified_at ?? 0) > (best.modified_at ?? 0)) best = conversation;
  }
  return best;
};

const SingleChatEmptyState: React.FC<Props> = ({ conversation_id }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { conversations } = useConversationHistoryContext();

  const { data: conversation } = useSWR(conversation_id ? ['single-conversation', conversation_id] : null, () =>
    getConversationOrNull(conversation_id)
  );

  const starters = useMemo(
    () => [
      { key: 'untangle', label: t('conversation.startPage.untangle'), prompt: t('conversation.startPage.untanglePrompt'), Icon: Waves },
      { key: 'makePlan', label: t('conversation.startPage.makePlan'), prompt: t('conversation.startPage.makePlanPrompt'), Icon: ListCheckbox },
      { key: 'research', label: t('conversation.startPage.research'), prompt: t('conversation.startPage.researchPrompt'), Icon: Search },
    ],
    [t]
  );

  const recent = useMemo(() => findMostRecentOther(conversations ?? [], conversation_id), [conversations, conversation_id]);

  if (!conversation) return null;

  return (
    <div data-testid='single-chat-empty-state' className={styles.container}>
      <MuraPresence compact className={styles.presence} />
      <h1 className={styles.greeting}>{t('conversation.startPage.greeting')}</h1>
      <p className={styles.supporting}>{t('conversation.startPage.supportingText')}</p>

      <div className={styles.starters}>
        {starters.map(({ key, label, prompt, Icon }) => (
          <button key={key} type='button' className={styles.chip} onClick={() => requestConversationSendBoxPrefill(conversation_id, prompt)}>
            <Icon theme='outline' size='16' className={styles.chipIcon} />
            <span>{label}</span>
          </button>
        ))}
      </div>

      {recent && (
        <button type='button' className={styles.resume} onClick={() => void navigate(`/conversation/${recent.id}`)}>
          <span className={styles.resumeLeft}>
            <span className={styles.resumeLabel}>{t('conversation.startPage.continue')}</span>
            <span className={styles.resumeTitle}>
              <FileText theme='outline' size='16' className={styles.resumeIcon} />
              {recent.name}
            </span>
          </span>
          <Right theme='outline' size='18' className={styles.resumeChevron} />
        </button>
      )}
    </div>
  );
};

export default SingleChatEmptyState;

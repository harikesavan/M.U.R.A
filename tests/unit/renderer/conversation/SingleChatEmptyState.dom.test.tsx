/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const useSWRMock = vi.fn();
const usePresetAssistantInfoMock = vi.fn();
const getConversationOrNullMock = vi.fn();
const requestConversationSendBoxPrefillMock = vi.fn();
const navigateMock = vi.fn();
const useConversationHistoryContextMock = vi.fn();

const translations: Record<string, string> = {
  'conversation.startPage.greeting': 'Hi, Hari.',
  'conversation.startPage.supportingText': "What's on your mind?",
  'conversation.startPage.untangle': 'Untangle a thought',
  'conversation.startPage.untanglePrompt': 'Help me untangle this thought: ',
  'conversation.startPage.makePlan': 'Make a plan',
  'conversation.startPage.makePlanPrompt': 'Help me make a clear, realistic plan for: ',
  'conversation.startPage.research': 'Research something',
  'conversation.startPage.researchPrompt': 'Research this and explain what matters most: ',
  'conversation.startPage.continue': 'Continue where you left off',
  'conversation.startPage.presenceAlt': 'Mura',
};

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, options?: { defaultValue?: string }) => translations[key] ?? options?.defaultValue ?? key,
  }),
}));

vi.mock('react-router-dom', () => ({
  useNavigate: () => navigateMock,
}));

vi.mock('swr', () => ({
  __esModule: true,
  default: (...args: unknown[]) => useSWRMock(...args),
}));

vi.mock('@/renderer/hooks/agent/usePresetAssistantInfo', () => ({
  usePresetAssistantInfo: (...args: unknown[]) => usePresetAssistantInfoMock(...args),
}));

vi.mock('@renderer/hooks/agent/usePresetAssistantInfo', () => ({
  usePresetAssistantInfo: (...args: unknown[]) => usePresetAssistantInfoMock(...args),
}));

vi.mock('@/renderer/pages/conversation/utils/conversationCache', () => ({
  getConversationOrNull: (...args: unknown[]) => getConversationOrNullMock(...args),
}));

vi.mock('@/renderer/hooks/chat/useSendBoxDraft', () => ({
  requestConversationSendBoxPrefill: (...args: unknown[]) => requestConversationSendBoxPrefillMock(...args),
}));

vi.mock('@/renderer/hooks/context/ConversationHistoryContext', () => ({
  useConversationHistoryContext: () => useConversationHistoryContextMock(),
}));

vi.mock('@renderer/utils/model/agentLogo', () => ({
  useAgentLogos: () => ({}),
  resolveAgentLogo: () => null,
  resolveAgentAvatar: () => ({ kind: 'fallback' }),
}));

import SingleChatEmptyState from '@/renderer/pages/conversation/components/SingleChatEmptyState';

describe('SingleChatEmptyState', () => {
  beforeEach(() => {
    useSWRMock.mockReset();
    usePresetAssistantInfoMock.mockReset();
    getConversationOrNullMock.mockReset();
    requestConversationSendBoxPrefillMock.mockReset();
    navigateMock.mockReset();
    useConversationHistoryContextMock.mockReturnValue({ conversations: [] });
  });

  it('renders Mura\'s calm personal greeting once the conversation record is available', () => {
    useSWRMock.mockReturnValue({
      data: { id: 'conv-1', type: 'acp', name: 'Some chat title', extra: { backend: 'claude' } },
    });
    usePresetAssistantInfoMock.mockReturnValue({ info: null });

    render(<SingleChatEmptyState conversation_id='conv-1' />);

    expect(screen.getByRole('heading', { name: 'Hi, Hari.' })).toBeInTheDocument();
    expect(screen.getByText("What's on your mind?")).toBeInTheDocument();
  });

  it('prefills the existing composer without sending when a starter action is selected', async () => {
    const user = userEvent.setup();
    useSWRMock.mockReturnValue({
      data: { id: 'conv-1', type: 'acp', name: 'Some chat title', extra: { backend: 'claude' } },
    });
    usePresetAssistantInfoMock.mockReturnValue({ info: null });

    render(<SingleChatEmptyState conversation_id='conv-1' />);
    await user.click(screen.getByRole('button', { name: 'Make a plan' }));

    expect(requestConversationSendBoxPrefillMock).toHaveBeenCalledWith(
      'conv-1',
      'Help me make a clear, realistic plan for: '
    );
  });

  it('resumes the most recently modified real conversation other than the current empty chat', async () => {
    const user = userEvent.setup();
    useSWRMock.mockReturnValue({
      data: { id: 'conv-current', type: 'acp', name: 'New Chat', extra: { backend: 'claude' } },
    });
    usePresetAssistantInfoMock.mockReturnValue({ info: null });
    useConversationHistoryContextMock.mockReturnValue({
      conversations: [
        { id: 'conv-current', name: 'New Chat', modified_at: 300 },
        { id: 'conv-older', name: 'Older work', modified_at: 100 },
        { id: 'conv-recent', name: 'Mura setup', modified_at: 200 },
      ],
    });

    render(<SingleChatEmptyState conversation_id='conv-current' />);
    await user.click(screen.getByRole('button', { name: /Continue where you left off.*Mura setup/ }));

    expect(navigateMock).toHaveBeenCalledWith('/conversation/conv-recent');
  });

  it('hides the resume entry when no other conversation exists', () => {
    useSWRMock.mockReturnValue({
      data: { id: 'conv-1', type: 'acp', name: 'Some chat title', extra: { backend: 'claude' } },
    });
    usePresetAssistantInfoMock.mockReturnValue({ info: null });
    useConversationHistoryContextMock.mockReturnValue({
      conversations: [{ id: 'conv-1', name: 'Some chat title', modified_at: 100 }],
    });

    render(<SingleChatEmptyState conversation_id='conv-1' />);

    expect(screen.queryByText('Continue where you left off')).not.toBeInTheDocument();
  });

  it('renders nothing until the conversation record loads', () => {
    useSWRMock.mockReturnValue({ data: undefined });
    usePresetAssistantInfoMock.mockReturnValue({ info: null });

    const { container } = render(<SingleChatEmptyState conversation_id='conv-1' />);

    expect(container).toBeEmptyDOMElement();
  });
});

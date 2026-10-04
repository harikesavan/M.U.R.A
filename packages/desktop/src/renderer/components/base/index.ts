/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * Mura 基础组件库统一导出 / Mura base components unified exports
 *
 * 提供所有基础组件和类型的统一导出入口
 * Provides unified export entry for all base components and types
 */

// ==================== 组件导出 / Component Exports ====================

export { default as MuraModal } from './MuraModal';
export { default as MuraCollapse } from './MuraCollapse';
export { default as MuraSelect } from './MuraSelect';
export { default as MuraScrollArea } from './MuraScrollArea';
export { default as MuraSteps } from './MuraSteps';
export { default as MuraSearchInput } from './MuraSearchInput';
export { default as MuraInlineSearchInput } from './MuraInlineSearchInput';

// ==================== 类型导出 / Type Exports ====================

// MuraModal 类型 / MuraModal types
export type {
  ModalSize,
  ModalHeaderConfig,
  ModalFooterConfig,
  ModalContentStyleConfig,
  MuraModalProps,
} from './MuraModal';
export { MODAL_SIZES } from './MuraModal';

// MuraCollapse 类型 / MuraCollapse types
export type { MuraCollapseProps, MuraCollapseItemProps } from './MuraCollapse';

// MuraSelect 类型 / MuraSelect types
export type { MuraSelectProps } from './MuraSelect';

// MuraSteps 类型 / MuraSteps types
export type { MuraStepsProps } from './MuraSteps';

// MuraSearchInput 类型 / MuraSearchInput types
export type { MuraSearchInputProps } from './MuraSearchInput';

// MuraInlineSearchInput 类型 / MuraInlineSearchInput types
export type { MuraInlineSearchInputProps } from './MuraInlineSearchInput';

/**
 * @license
 * Copyright 2025 Mura (mura.com)
 * SPDX-License-Identifier: Apache-2.0
 */

import { Steps } from '@arco-design/web-react';
import type { StepsProps } from '@arco-design/web-react/es/Steps';
import classNames from 'classnames';
import React from 'react';

/**
 * 步骤条组件属性 / Steps component props
 */
export interface MuraStepsProps extends StepsProps {
  /** 额外的类名 / Additional class name */
  className?: string;
}

/**
 * 步骤条组件 / Steps component
 *
 * 基于 Arco Design Steps 的封装，提供统一的样式主题
 * Wrapper around Arco Design Steps with unified theme styling
 *
 * @features
 * - 自定义品牌色主题 / Custom brand color theme
 * - 完成态的特殊样式处理 / Special styling for finished state
 * - 完整的 Arco Steps API 支持 / Full Arco Steps API support
 *
 * @example
 * ```tsx
 * // 基本用法 / Basic usage
 * <MuraSteps current={1}>
 *   <MuraSteps.Step title="步骤1" description="这是描述" />
 *   <MuraSteps.Step title="步骤2" description="这是描述" />
 *   <MuraSteps.Step title="步骤3" description="这是描述" />
 * </MuraSteps>
 *
 * // 垂直步骤条 / Vertical steps
 * <MuraSteps current={1} direction="vertical">
 *   <MuraSteps.Step title="步骤1" description="描述" />
 *   <MuraSteps.Step title="步骤2" description="描述" />
 * </MuraSteps>
 *
 * // 带图标的步骤条 / Steps with icons
 * <MuraSteps current={1}>
 *   <MuraSteps.Step title="完成" icon={<IconCheck />} />
 *   <MuraSteps.Step title="进行中" icon={<IconLoading />} />
 *   <MuraSteps.Step title="待处理" icon={<IconClock />} />
 * </MuraSteps>
 *
 * // 迷你版步骤条 / Mini steps
 * <MuraSteps current={1} size="small" type="dot">
 *   <MuraSteps.Step title="步骤1" />
 *   <MuraSteps.Step title="步骤2" />
 *   <MuraSteps.Step title="步骤3" />
 * </MuraSteps>
 * ```
 *
 * @see arco-override.css for custom styles (.mura-steps)
 */
const MuraSteps: React.FC<MuraStepsProps> & { Step: typeof Steps.Step } = ({ className, ...props }) => {
  return <Steps {...props} className={classNames('mura-steps', className)} />;
};

MuraSteps.displayName = 'MuraSteps';

// 导出子组件 / Export sub-component
MuraSteps.Step = Steps.Step;

export default MuraSteps;

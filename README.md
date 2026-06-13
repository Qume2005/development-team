# development-team: Claude Code 的 IT 项目经理插件

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://docs.anthropic.com/en/docs/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Qume2005/development-team/pulls)

> **把所有工作委托给专业子代理的 IT 团队项目管理系统**

如果你用 Claude Code 做过复杂任务，大概率遇到过这个问题：随着对话变长，上下文窗口被代码片段、diff、日志逐渐填满，判断力和记忆随之衰退。做到一半，可能已经忘了最初的需求。**上下文是不可再生的稀缺资源**——一旦消耗，无法恢复。

development-team 正是为解决这个问题而设计的。核心理念：AI 代理扮演 IT 项目经理，而**项目经理从不亲自干活**——只理解需求、设计工作流、调度专业子代理、根据子代理返回的简短结论做决策。所有上下文通过磁盘上的结构化文档流转；项目经理从不读取实际交付物。

---

## 核心特性

| 特性 | 说明 |
|------|------|
| **16 个专业角色** | 1 个 PM + 9 个生产角色 + 7 个审核角色，各司其职 |
| **结构化工作流** | 产品设计 -> 架构 -> 计划 -> API -> 测试 -> 代码 -> 审核，自动匹配 |
| **PreToolUse Hook 强制执行** | 引导阶段 + 运行阶段双重保障，PM 无法绕过工具限制 |
| **Superpowers 插件兼容** | sp-* bridge 自动桥接 TDD、brainstorming 等增强技能 |
| **上下文保护** | PM 永不读文件，只吸收 3-5 行摘要；子代理按模块范围工作 |
| **交付物审查制度** | 所有产出必须通过配对审核员，最多 3 轮；失败上报用户 |
| **并行调度** | 独立子任务同时派发，下游依赖在上游审核通过后启动 |
| **零依赖** | 纯 Markdown，零构建步骤，零配置——23 个技能目录 + hooks + manifest 即完整产品 |

---

## 工作原理

```
用户提需求
    |
    v
+------------------+     +-------------------+
|  Project Manager |<--->|  Intern (读文件)   |
|  理解 / 设计 / 决策  |     +-------------------+
+------------------+              |
    |                             |
    | 逐级委托（磁盘文档传递上下文）
    v
+------------------+     +-------------------+
| Product Designer |---->| Product Reviewer  |---> 通过?
+------------------+     +-------------------+      |
                                                    v
+------------------+     +-------------------+   PM 继续
| Architect        |---->| Architect Reviewer |---> 调度
+------------------+     +-------------------+
    |
    v
+------------------+     +-------------------+
| Task Planner     |---->| Task Reviewer     |
+------------------+     +-------------------+
    |
    v
+------------------+     +-------------------+
| API Designer     |---->| API Reviewer      |
+------------------+     +-------------------+
    |
    v
+------------------+     +-------------------+
| Test Designer    |---->| Test Design Review|
+------------------+     +-------------------+
    |                        (TDD: 测试先行)
    v
+------------------+     +-------------------+
| Code Developer   |---->| Code Reviewer     |
+------------------+     +-------------------+
    |
    v
  交付给用户
```

**核心原则：PM 永远不是管道。** 子代理之间通过磁盘上的结构化文档协作，而非对话。

---

## 角色一览

### 生产角色（产出交付物）

| 角色 | 技能 | 职责 |
|------|------|------|
| Project Manager | `development-team:pm` | 理解需求、设计工作流、调度子代理、做决策——但绝不亲自干活 |
| Product Designer | `development-team:product-designer` | 设计产品规格、用户故事、功能优先级 |
| Architecture Designer | `development-team:architect` | 设计系统架构、模块拆分、技术选型 |
| Task Planner | `development-team:planner` | 将任务分解为可执行单元、编写计划 |
| API Designer | `development-team:api-designer` | 设计 API、接口契约 |
| Test Designer | `development-team:test-designer` | 设计集成测试和系统测试（TDD：测试先行） |
| Code Developer | `development-team:coder` | 编写代码 + 单元测试，运行所有测试，确保通过 |
| Document Writer | `development-team:doc-writer` | 编写文档、文章、规格说明 |
| Intern | `development-team:intern` | 杂务 + PM 的阅读代理——清理、归档、文件操作、为 PM 读取并摘要 |

### 审核角色（质量把关）

| 角色 | 技能 | 审核对象 |
|------|------|---------|
| Product Reviewer | `development-team:product-reviewer` | 产品设计——用户价值、完整性、优先级 |
| Architecture Reviewer | `development-team:architect-reviewer` | 架构设计——模块化、可扩展性、可行性 |
| Task Reviewer | `development-team:task-reviewer` | 执行计划——可行性、范围、分解质量 |
| API Reviewer | `development-team:api-reviewer` | API 设计——正确性、一致性、易用性 |
| Test Design Reviewer | `development-team:test-design-reviewer` | 测试设计——完整性、正确性、边界情况 |
| Code Reviewer | `development-team:code-reviewer` | 代码 + 测试——缺陷、覆盖率、可维护性、TDD 合规 |
| Document Reviewer | `development-team:doc-reviewer` | 文档——清晰度、准确性、完整性 |

---

## 安装

### 方式一：手动安装（推荐）

```bash
# 克隆到 Claude Code 技能目录
git clone https://github.com/Qume2005/development-team.git ~/.claude/skills/development-team

# 赋予 hook 脚本执行权限
chmod +x ~/.claude/skills/development-team/hooks/*
```

### 方式二：社区市场（发布后可用）

```bash
/plugin install development-team@claude-community
```

安装后，每次启动 Claude Code 对话都会自动进入项目经理模式。

---

## 使用

启动 Claude Code 后，直接描述你的需求：

```
> 帮我构建一个带 JWT 和 OAuth2 的用户认证系统

# 项目经理会自动：
# 1. 派 Intern 读取并评估项目范围
# 2. 提议 Full System Development 工作流
# 3. 等待你的确认后执行
```

简单任务同样适用：

```
> 修复登录页面的一个拼写错误

# 项目经理选择 Quick Fix 工作流：
# Code Developer -> Code Reviewer -> 交付
```

所有中间产物和最终交付物存储在项目的 `.claude/development-team/` 目录下，按角色扁平组织。

---

## 与 Superpowers 插件兼容

development-team 通过 **sp-* bridge 技能**与 [superpowers](https://github.com/nicekid1/superpowers) 插件无缝集成：

| Bridge 技能 | 增强对象 | 桥接的 Superpowers 技能 |
|-------------|---------|------------------------|
| `sp-pm` | Project Manager | `subagent-driven-development` |
| `sp-planner` | Task Planner | `brainstorming`, `writing-plans` |
| `sp-architect` | Architecture Designer | `brainstorming`, `writing-plans` |
| `sp-product-designer` | Product Designer | `brainstorming` |
| `sp-coder` | Code Developer | `TDD`, `debugging`, `verification`, `executing-plans`, `git-worktrees` |
| `sp-test-designer` | Test Designer | `TDD`, `systematic-debugging` |
| `superpower-cowork` | 所有子代理 | 检测 superpowers 可用性，按场景引导调用 |

**工作原理：**
- PM 在引导阶段检测 superpowers 是否安装
- 如果已安装，PM 加载 `sp-pm`，并在派发子代理时告知其加载对应的 `sp-*` bridge
- 如果未安装，系统正常工作，无任何报错或降级提示
- PM 自身不直接调用任何 superpowers 技能（除 `subagent-driven-development`），所有增强通过子代理 bridge 执行

---

## Hook 强制执行机制

development-team 使用 Claude Code 的 PreToolUse Hook 实现两层结构执行，确保 PM 无法绕过工具限制：

### L1: 引导阶段

```
会话启动
    |
    v
SessionStart hook: 清除所有标记，注入 bootstrap 上下文
    |
    v
用户尝试使用工具（Read/Bash/Write/Edit 等）
    |
    v
PreToolUse hook 检查: PM_LOADED 标记存在?
    |
    +---> 不存在: 阻止工具调用
         "development-team active but PM skills not loaded.
          Invoke via Skill tool FIRST:
          1) development-team:pm
          2) development-team
          Then retry."
```

**效果：** 会话刚启动时，PM skill 尚未加载，所有工作工具被阻止。代理必须先通过 Skill 工具加载 PM skill，才能继续操作。

### L2: 运行阶段

```
PM skill 加载
    |
    v
PreSkillUse hook: 创建 PM_LOADED + PM_RESTRICTED 标记
    |
    v
PM 尝试使用工具
    |
    v
PreToolUse hook 检查优先级:
    1. 子代理活跃中?  -> 允许（子代理无限制）
    2. PM_RESTRICTED 标记存在? -> 阻止
       "PM tool restriction active. Dispatch a subagent instead."
    3. PM_LOADED 存在但无限制 -> 允许（故障开放）
```

**效果：** PM 自愿激活工具限制（通过加载其 skill 触发），Read/Bash/Write/Edit 被阻止。子代理派发时，PreAgentUse hook 递增活跃计数器，PostAgentUse hook 递减——子代理活跃期间所有工具正常放行。

---

## 项目结构

```
development-team/
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── hooks/
│   ├── hooks.json               # Hook 注册配置
│   ├── session-start            # 会话启动引导注入
│   ├── pre-skill-use            # Skill 工具钩子（标记管理）
│   ├── pre-tool-use             # 工作工具钩子（PM 限制执行）
│   ├── pre-agent-use            # Agent 派发钩子（活跃计数+1）
│   ├── post-agent-use           # Agent 完成钩子（活跃计数-1）
│   └── run-hook.cmd             # 跨平台启动器
├── skills/
│   ├── development-team/        # 主技能——共享规则 + bootstrap
│   │   ├── SKILL.md
│   │   └── bootstrap.md
│   ├── pm/                      # 项目经理
│   ├── product-designer/        # 产品设计师
│   ├── architect/               # 架构设计师
│   ├── planner/                 # 任务规划师
│   ├── api-designer/            # API 设计师
│   ├── test-designer/           # 测试设计师
│   ├── coder/                   # 代码开发者
│   ├── doc-writer/              # 文档编写者
│   ├── intern/                  # 实习生
│   ├── product-reviewer/        # 产品审核员
│   ├── architect-reviewer/      # 架构审核员
│   ├── task-reviewer/           # 任务审核员
│   ├── api-reviewer/            # API 审核员
│   ├── test-design-reviewer/    # 测试设计审核员
│   ├── code-reviewer/           # 代码审核员
│   ├── doc-reviewer/            # 文档审核员
│   ├── superpower-cowork/       # Superpowers 检测与引导
│   ├── sp-pm/                   # PM bridge
│   ├── sp-planner/              # Planner bridge
│   ├── sp-architect/            # Architect bridge
│   ├── sp-product-designer/     # Product Designer bridge
│   ├── sp-coder/                # Coder bridge
│   └── sp-test-designer/        # Test Designer bridge
├── LICENSE                      # MIT 许可证
├── .gitignore
└── README.md                    # 本文件
```

**总计：23 个技能目录 + bootstrap.md + hooks/ + .claude-plugin/ = 完整插件。**

---

## 开发与贡献

这是个人项目，目前由独立开发者维护。如果你有建议或发现 bug，欢迎在 [GitHub Issues](https://github.com/Qume2005/development-team/issues) 提交。

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/Qume2005/development-team.git
cd development-team

# 修改技能文件后，直接复制到技能目录测试
cp -r . ~/.claude/skills/development-team
chmod +x ~/.claude/skills/development-team/hooks/*
```

---

## 致谢

development-team 的灵感来自一个直白的观察：**AI 代理的上下文窗口是最宝贵的资源**，然而大多数交互模式都在无意识地挥霍它。感谢 Anthropic Claude Code 团队提供的技能系统和子代理机制，使这种「项目经理模式」成为可能。

---

## License

[MIT License](LICENSE) Copyright (c) 2025 Qume

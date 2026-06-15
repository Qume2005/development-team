# development-team: 给 Claude Code 配一支完整的 AI 开发团队

> **16 个专业角色 + 严格审核流程——一支协同作业的 AI 开发团队，分工明确、逐道把关。**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://docs.anthropic.com/en/docs/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Qume2005/development-team/pulls)

## ⚡ 快速开始

**一行命令装好，然后把需求甩给团队——剩下的事，团队来。**

```bash
git clone https://github.com/Qume2005/development-team.git ~/.claude/skills/development-team
chmod +x ~/.claude/skills/development-team/hooks/*
```

🧹 需要卸载？直接跳到 [快速卸载](#快速卸载)。

装完启动 Claude Code，直接说一句你要什么（比如「帮我做一个带 JWT 的登录系统」）。团队会自己接手：理解需求 → 设计方案 → 拆任务 → 编码 → 审核 → 交付。你只管提需求、看结果。

---

## 这是一支怎样的团队

一次安装，然后把整个任务交给团队。

你只要说清目标，剩下的全由一支 16 人的 AI 开发团队端到端完成：理清范围 → 设计架构 → 拆解任务 → 设计接口 → 编写测试 → 敲定代码 → 逐道审核 → 交付成果。整条流水线自动跑通，每一份产出都要经过配对审核员的把关。

development-team 把这套协作模式搬进 Claude Code：9 个生产角色各司其职地产出，7 个审核角色逐道把关，项目经理（PM）在其中只做协调——理解需求、设计工作流、调度子代理、做决策，**不亲自干活**。所有工作通过磁盘上的交付文档在角色之间流转，每一份产出都必须通过配对审核（最多 3 轮），Hook 强制执行规则。

简单说，它给你的是一支分工清楚、流程严格、上下文纪律靠结构保证的团队——你负责提需求，团队负责把它做出来。

---

## 核心特性

| 特性 | 说明 |
|------|------|
| **一支 16 人的团队** | 9 个生产角色（架构师 / 产品设计师 / 任务规划 / API 设计师 / 测试设计师 / 编码 / 文档 / 实习生 / PM）+ 7 个审核角色，平权协作 |
| **逐道审核流程** | 每一份产出都经过配对审核员，最多 3 轮；失败则回滚并上报用户 |
| **磁盘文档驱动协作** | 角色之间通过磁盘上的结构化交付文档流转上下文，无需对话传递 |
| **Hook 强制执行** | PreToolUse Hook 双层保障（L1 引导 / L2 运行），PM 的工具限制无法被绕过 |
| **上下文保护** | PM 永不读文件，只吸收 3-5 行摘要；各生产角色按模块范围（1 模块 / 2-3 文件）专注工作 |
| **结构化工作流** | 产品设计 -> 架构 -> 计划 -> API -> 测试 -> 代码 -> 审核，按任务大小自动匹配 |
| **并行调度** | 独立子任务同时派发，下游依赖在上游审核通过后才启动 |
| **零依赖** | 纯 Markdown，零构建步骤，零配置——技能目录 + hooks + manifest 即完整产品 |

---

## 工作原理

团队以磁盘文档为协作管道。每一阶段的产出文档，就是下一阶段的输入：

```
用户提需求
    |
    v
+------------------+     +-------------------+
|  Project Manager |<--->|  Intern (读文件)   |
|  协调 / 决策 / 调度  |     +-------------------+
+------------------+              |
    |                             |
    | 团队协作（磁盘文档传递上下文）
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

**团队协作的核心原则：PM 永远不是管道。** 各生产角色读自己需要的源码与上游文档、产出交付物、交由配对审核员把关；角色之间靠磁盘上的结构化文档协作，无需对话。PM 只追踪文档路径、吸收审核结论（通过/失败 + 关键问题），据此决定下一步调度。

---

## 角色一览

这是一支 16 人的团队。生产角色负责产出，审核角色负责把关，二者**平权呈现**——团队的价值来自这 16 个角色协作 + 严格审核流程。

### 生产角色（产出交付物）

| 角色 | 技能 | 职责 |
|------|------|------|
| Product Designer | `development-team:product-designer` | 设计产品规格、用户故事、功能优先级 |
| Architecture Designer | `development-team:architect` | 设计系统架构、模块拆分、技术选型 |
| Task Planner | `development-team:planner` | 将任务分解为可执行单元、编写计划 |
| API Designer | `development-team:api-designer` | 设计 API、接口契约 |
| Test Designer | `development-team:test-designer` | 设计集成测试和系统测试（TDD：测试先行） |
| Code Developer | `development-team:coder` | 编写代码 + 单元测试，运行所有测试，确保通过 |
| Document Writer | `development-team:doc-writer` | 编写文档、文章、规格说明 |
| Intern | `development-team:intern` | 杂务 + PM 的阅读代理——清理、归档、文件操作、为 PM 读取并摘要 |
| Project Manager | `development-team:pm` | 团队里的协调角色：理解需求、设计工作流、调度子代理、做决策——**不亲自写代码 / 读文件 / 跑命令** |

### 审核角色（质量把关）

每一份生产产出都流向其配对审核员。审核是依赖链的一环——下游工作必须等上游审核通过才能启动。

| 角色 | 技能 | 审核对象 |
|------|------|---------|
| Product Reviewer | `development-team:product-reviewer` | 产品设计——用户价值、完整性、优先级 |
| Architecture Reviewer | `development-team:architect-reviewer` | 架构设计——模块化、可扩展性、可行性 |
| Task Reviewer | `development-team:task-reviewer` | 执行计划——可行性、范围、分解质量 |
| API Reviewer | `development-team:api-reviewer` | API 设计——正确性、一致性、易用性 |
| Test Design Reviewer | `development-team:test-design-reviewer` | 测试设计——完整性、正确性、边界情况 |
| Code Reviewer | `development-team:code-reviewer` | 代码 + 测试——缺陷、覆盖率、可维护性、TDD 合规 |
| Document Reviewer | `development-team:doc-reviewer` | 文档——清晰度、准确性、完整性 |

> **关于 PM：** PM 是这 16 个角色里唯一的协调角色。它不写代码、不读文件、不跑命令——这是事实，也是它准确的工作边界。团队的价值在于其余角色各司其职地产出，以及 7 个审核员逐道把关；PM 的工作是让这套协作高效运转、守住上下文纪律。

---

## 安装

两种方式任选其一。**推荐用方式一——它就是上面「快速开始」里那条一行命令的安装路径，克隆即用。**

### 方式一：git clone（推荐 · 一行命令装好）

```bash
# 克隆到 Claude Code 技能目录
git clone https://github.com/Qume2005/development-team.git ~/.claude/skills/development-team

# 赋予 hook 脚本执行权限
chmod +x ~/.claude/skills/development-team/hooks/*
```

两行命令跑完即装好，无需额外配置。

### 方式二：社区市场（发布后可用）

```bash
/plugin install development-team@claude-community
```

> **注意：** 此命令在市场正式发布后才可用，当前请使用方式一。

安装后，每次启动 Claude Code 对话都会自动唤醒这支团队。

---

## 快速卸载

不想用了？两步干净移除（本地 `git clone` 安装不受 `/plugin uninstall` 管理，需手动清理）：

```bash
rm -rf ~/.claude/skills/development-team
```

然后（可选但推荐）清理注册表：编辑 `~/.claude/plugins/installed_plugins.json`，删掉整个 `"development-team@local": [ ... ]` 块，注意保持 JSON 合法（别留下多余逗号）。`settings.json` 无需改动。

改完重启 Claude Code（或执行 `/clear`），团队就不会在下一次会话自动唤醒——彻底停用。

---

## 使用

**装好之后，你只做一件事：用一句话描述你要什么，然后放手。**

团队会自动按任务大小匹配工作流，从理解需求一路跑到交付，全程带配对审核——你不需要拆任务、不需要盯流程、不需要逐个催角色。

**大任务 → 完整工作流（全员出动，逐道审核）：**

```
> 帮我构建一个带 JWT 和 OAuth2 的用户认证系统

# 团队会自动：
# 1. PM 派 Intern 读取并评估项目范围
# 2. PM 提议 Full System Development 工作流（含产品/架构/计划/API/测试/编码各角色 + 审核）
# 3. 等待你确认后，各角色并行/串行执行，逐道审核
```

**小任务 → Quick Fix（按需裁剪，快进快出）：**

```
> 修复登录页面的一个拼写错误

# PM 选择 Quick Fix 工作流：
# Code Developer -> Code Reviewer -> 交付
```

无论任务大小，每一份产出都必须通过配对审核员的把关（最多 3 轮），失败则回滚上报。所有中间产物和最终交付物存储在项目的 `.claude/development-team/` 目录下，按角色扁平组织。

---

## Hook 强制执行机制

团队纪律靠 Hook 强制执行，而非靠自觉。development-team 使用 Claude Code 的 PreToolUse Hook 实现两层结构，确保 PM 无法绕过工具限制：

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

**效果：** PM 自愿激活工具限制（通过加载其 skill 触发），Read/Bash/Write/Edit 被阻止。子代理派发时，PreAgentUse hook 递增活跃计数器，PostAgentUse hook 递减——子代理活跃期间所有工具正常放行。生产角色因此能自由读写，PM 的上下文纪律则在结构上得到保证。

---

## 项目结构

```
development-team/
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── agents/                      # 15 native Claude Code plugin agents (flat .md files)
│   ├── intern.md
│   ├── coder.md
│   ├── planner.md
│   ├── architect.md
│   ├── product-designer.md
│   ├── api-designer.md
│   ├── test-designer.md
│   ├── doc-writer.md
│   ├── task-reviewer.md
│   ├── api-reviewer.md
│   ├── architect-reviewer.md
│   ├── product-reviewer.md
│   ├── test-design-reviewer.md
│   ├── code-reviewer.md
│   └── doc-reviewer.md
├── hooks/
│   ├── hooks.json               # Hook 注册配置
│   ├── session-start            # 会话启动引导注入
│   ├── pre-skill-use            # Skill 工具钩子（标记管理）
│   ├── pre-tool-use             # 工作工具钩子（PM 限制执行）
│   ├── pre-agent-use            # Agent 派发钩子（活跃计数+1）
│   ├── post-agent-use           # Agent 完成钩子（活跃计数-1）
│   └── run-hook.cmd             # 跨平台启动器
├── skills/
│   ├── development-team/        # 共享系统规则 + bootstrap
│   │   ├── SKILL.md
│   │   └── bootstrap.md
│   └── pm/                      # PM 技能（协调角色的专属规则）
├── LICENSE                      # MIT 许可证
├── .gitignore
└── README.md                    # 本文件
```

**总计：15 个原生 agent（`agents/*.md`）+ PM skill（`development-team:pm`）+ 共享 `development-team` skill = 16 个角色。bootstrap.md + hooks/ + .claude-plugin/ = 完整插件。15 个被派发的角色都是原生 Claude Code 插件代理（`agents/*.md`），PM 与共享规则仍以技能形式保留。**

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

development-team 的灵感来自一个直白的观察：**一支好的开发团队靠的是分工协作与严格的质量把关**，每个环节都有专人产出、有专人审核。感谢 Anthropic Claude Code 团队提供的技能系统和子代理机制，让一支分工明确、带审核流程的 AI 开发团队成为可能。

---

## License

[MIT License](LICENSE) Copyright (c) 2025 Qume
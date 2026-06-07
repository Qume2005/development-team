[English Version](README.md)

# DevelopmentTeam

> 一个让 AI agent 化身 IT 团队项目经理的 Claude Code skill — 用 17 个专业角色协作完成软件工程任务，同时守护你宝贵的 context window。

---

## 项目简介

如果你用过 Claude Code 处理复杂任务，你一定遇到过这个问题：随着会话越来越长，agent 的上下文窗口（context window）逐渐被代码片段、diff、日志填满，它的判断力和记忆力也随之下降。等到任务做到一半，它可能已经忘了最开始的需求是什么。**context 是稀缺且不可再生的资源** — 一旦消耗，无法恢复。

**DevelopmentTeam** 正是为了解决这个问题而诞生的。它的核心理念很简单：让 AI agent 扮演一位 IT 团队项目经理，**项目经理从不亲自动手** — 它只负责理解需求、设计工作流、派遣专业子角色（subagent）执行，然后根据子角色返回的简要裁决（1-2 句话摘要）做出决策。所有上下文通过磁盘上的结构化文档流转，项目经理永远不直接阅读交付物本身。

这不是一个代码库，也不是一个框架。它是一组精心设计的 Markdown 规则文件（共 19 个），安装到 `~/.claude/skills/` 目录后，就能让 Claude Code 的每一次对话自动进入「项目经理模式」。无论你是要构建一个全新的全栈项目，还是修一个小 bug，DevelopmentTeam 都会自动匹配最合适的工作流模板，以 TDD、代码审查、质量门控的方式交付高质量的成果。

---

## 核心理念

| 原则 | 说明 |
|------|------|
| **Context 是稀缺资源** | Agent 的 context window 有限且不可恢复，必须像管理预算一样精打细算 |
| **项目经理从不亲自动手** | Project Manager 永远不读代码、不写文档、不跑命令 — 所有实际工作委派给 subagent |
| **磁盘是通信管道** | 子角色之间不通过对话传递上下文，而是通过 `.claude/the-company/` 目录下的结构化交付文档 |
| **只吸收裁决** | Project Manager 只接收文件路径 + 1-2 句话的结论，用于决策，绝不阅读完整交付物 |

---

## 功能特性

- **17 个专业角色** — 10 个生产角色 + 7 个审查角色，各司其职，权责分明
- **7 种工作流模板（+自定义）** — 从 Greenfield 全新项目到 Quick Fix 快速修复，按任务复杂度自动匹配
- **TDD 优先** — Test Designer 先写测试，Code Developer 再实现，确保质量从源头抓起
- **审查门控（Review Gate）** — 每个生产交付物必须通过配对审查角色的审核，最多 3 轮，不通过则升级至用户
- **并行执行** — Task Planner 识别独立子任务，支持同组并行派发，审查通过后才启动下游依赖
- **失败处理** — 覆盖 subagent 崩溃、输出不完整、审查循环、权限错误、Git 冲突等 8+ 种失败模式
- **会话恢复** — 交付文档持久化在磁盘上，会话中断后派遣 Summarizer 读取状态，从断点恢复
- **Pre-flight 安全检查** — 执行前评估 Git 状态、项目目录风险，修改项目外文件时提供三种安全选项
- **强制 Task 追踪** — 使用 `TaskCreate` 创建可见进度列表，用户在面板中实时看到每一步的状态
- **强制派遣公告** — 每次派发 subagent 必须输出自然语言公告，说明谁、做什么、为什么
- **权限矩阵** — 每个角色对交付文档的读/写/审查权限精确定义，防止越权操作
- **文档推荐矩阵** — 每个生产角色被明确告知应读取哪些前置交付文档，确保上下文流转正确
- **纯 Markdown 实现** — 零依赖、零构建、零配置，19 个 `.md` 文件即全部

---

## 角色一览表

### 生产角色（Production Roles）

| 角色 | 文件 | 职责 |
|------|------|------|
| Project Manager（项目经理） | `SKILL.md` | 理解需求、设计工作流、派遣子角色、做决策 — 但从不亲自动手 |
| Architecture Designer | `architect.md` | 设计系统架构、模块拆分、技术选型 |
| Product Designer | `product-designer.md` | 设计产品规格、用户故事、功能优先级 |
| Task Planner | `planner.md` | 将任务拆解为小单元，编写执行计划 |
| API Designer | `api-designer.md` | 设计 API、接口、契约 |
| Test Designer | `test-designer.md` | 设计集成测试与系统测试（TDD：测试先行） |
| Code Developer | `coder.md` | 编写代码 + 单元测试，运行所有测试，确保通过 |
| Document Writer | `doc-writer.md` | 编写文档、文章、规格说明 |
| Intern（实习生） | `intern.md` | 杂务 — 清理、归档、文件操作、简单事务 |
| Summarizer | `summarizer.md` | 重度上下文消费者 — 阅读论文、项目、代码库以提炼答案 |

### 审查角色（Review Roles）

| 角色 | 文件 | 审查对象 |
|------|------|----------|
| Architecture Reviewer | `architect-reviewer.md` | 架构设计 — 模块化、可扩展性、可行性 |
| Product Reviewer | `product-reviewer.md` | 产品设计 — 用户价值、完整性、优先级 |
| Task Reviewer | `task-reviewer.md` | 执行计划 — 可行性、范围、拆解质量 |
| API Reviewer | `api-reviewer.md` | API 设计 — 正确性、一致性、易用性 |
| Test Design Reviewer | `test-design-reviewer.md` | 测试设计 — 完整性、正确性、边界情况 |
| Code Reviewer | `code-reviewer.md` | 代码 + 测试 — Bug、覆盖率、可维护性、TDD 合规性 |
| Document Reviewer | `doc-reviewer.md` | 文档 — 清晰度、准确性、完整性 |

---

## 工作流模板一览

| 模板 | 适用场景 | 典型流程 |
|------|----------|----------|
| **Greenfield System Development** | 从零开始的新项目（2+ 模块） | （可选）产品设计 → 架构设计 → 计划 → 集成 TDD（每单元） → 系统测试 → 交付 |
| **Architectural Refactoring** | 架构级重构（单体→微服务等） | 架构设计 → 计划 → 集成 TDD → 系统测试 → 交付 |
| **Full System Development** | 大型功能、新模块 | 计划 → 集成 TDD → 系统测试 → 交付 |
| **Standard Development** | 中型功能、重构、新接口 | 计划 → API 设计 → 编码 + 单元测试 → 交付 |
| **Quick Fix** | 小 bug、拼写错误、配置修改 | 编码 → 代码审查 → 交付 |
| **Investigation Only** | 调研、分析、提问 | Summarizer 调研 → 交付结论 |
| **Documentation Only** | README、指南、文章 | Document Writer → 文档审查 → 交付 |

每个模板中，生产角色的交付物都会经过配对审查角色的审核，审查通过后才进入下一步。Project Manager 会根据任务的实际情况选择合适的模板，也可以自定义流程。

---

## 安装与使用

### 前置要求

- 已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Claude Code 的 skill 目录位于 `~/.claude/skills/`

### 安装步骤

```bash
# 1. 克隆仓库到 Claude Code skills 目录
git clone https://github.com/your-username/the-company.git ~/.claude/skills/the-company

# 2. 验证安装 — 确认以下文件存在
ls ~/.claude/skills/the-company/SKILL.md
ls ~/.claude/skills/the-company/system.md
```

安装完成后，Claude Code 的每次对话都会自动激活 DevelopmentTeam skill。Project Manager 会自动接管，分析你的请求并提议工作流。

### 使用示例

启动 Claude Code 后，直接描述你的需求即可：

```
> 帮我搭建一个用户认证系统，支持 JWT 和 OAuth2

# Project Manager 会自动：
# 1. 派遣 Summarizer 评估项目范围
# 2. 提议一个 Full System Development 工作流
# 3. 等待你确认后开始执行
```

对于简单任务：

```
> 修复登录页面的拼写错误

# Project Manager 会选择 Quick Fix 流程：
# Code Developer → Code Reviewer → 交付
```

### 交付目录

所有中间产物和最终交付物存储在项目的 `.claude/the-company/` 目录下：

```
.claude/the-company/<任务描述>-<日期>-<时间>/
  ├── plan-xxx.md              # 执行计划
  ├── api-design-xxx.md        # API 设计文档
  ├── test-design-xxx.md       # 测试设计文档
  ├── code-xxx.md              # 代码实现记录
  ├── review-xxx-round1.md     # 审查反馈
  └── summary-xxx.md           # 调研摘要
```

---

## 项目结构

```
the-company/
├── SKILL.md                     # 入口 / Project Manager 规则（Skill 清单）
├── system.md                    # 共享系统概述（所有角色读取）
├── .gitignore                   # 忽略 .claude/, .idea/, .vscode/
│
├── 📦 Production Roles (10):
│   ├── architect.md             # Architecture Designer
│   ├── product-designer.md      # Product Designer
│   ├── planner.md               # Task Planner
│   ├── api-designer.md          # API Designer
│   ├── test-designer.md         # Test Designer
│   ├── coder.md                 # Code Developer
│   ├── doc-writer.md            # Document Writer
│   ├── intern.md                # Intern（杂务）
│   └── summarizer.md            # Summarizer（重度上下文消费者）
│
├── 🔍 Review Roles (7):
│   ├── architect-reviewer.md    # 审查架构设计
│   ├── product-reviewer.md      # 审查产品设计
│   ├── task-reviewer.md         # 审查执行计划
│   ├── api-reviewer.md          # 审查 API 设计
│   ├── test-design-reviewer.md  # 审查测试设计
│   ├── code-reviewer.md         # 审查代码 + 测试
│   └── doc-reviewer.md          # 审查文档
│
└── .claude/the-company/         # 运行时交付目录
    └── deprecated/              # 归档的旧交付文档
```

**总计：2 个核心系统文件 + 17 个角色定义文件 = 19 个 Markdown 文件。**

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## 贡献 / Contributing

这是一个个人项目，目前由一位开发者独立维护。如果你有建议或发现 bug，欢迎通过 [GitHub Issues](https://github.com/your-username/DevelopmentTeam/issues) 反馈。

## 致谢

DevelopmentTeam 的设计灵感来自于一个朴素的观察：**AI agent 的 context window 是最宝贵的资源**，而大多数交互模式都在无意识地挥霍它。感谢 Anthropic 的 Claude Code 团队提供了 skill 系统和 subagent 机制，让这种「项目经理模式」成为可能。

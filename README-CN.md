# development-team

> 一个 Claude Code 插件 —— 它把主 agent 变成一名 IT 项目经理：负责界定范围、提出工作流、调度 19 个专门的原生子 agent，并用配对的评审者对每一个交付物把关。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://docs.anthropic.com/en/docs/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Qume2005/development-team/pulls)

[English](README.md) | **简体中文**

---

## 详情目录

- [它是什么](#它是什么)
- [📦 安装](#-安装)
- [🚀 使用](#-使用)
- [✨ 功能特性](#-功能特性)
- [🧠 工作原理](#-工作原理)
- [👥 角色（共 20 个）](#-角色共-20-个)
- [🛠️ Skills（共 9 个）](#️-skills共-9-个)
- [⚙️ Hooks](#️-hooks)
- [❓ 常见问题与排错](#-常见问题与排错)
- [📐 项目结构](#-项目结构)
- [🤝 贡献](#-贡献)
- [License](#license)

---

## 它是什么

`development-team` 是一个 Claude Code 插件（v1.0.0，MIT 协议，作者 [Qume2005](https://github.com/Qume2005)），它让主 agent 进入 **IT 项目经理工作模式**。PM 自己从不亲手做活 —— 它界定任务范围、提出工作流、调度专门的原生子 agent，并根据评审结论做出决策。**每一个生产交付物都要先经过配对评审者的把关（PASS/FAIL，最多 3 轮）。**

为什么你需要它：

- **结构化的工作流** —— 一个请求会沿着一条真正的流水线流动：产品设计 → 架构 → 规划 → API 设计 → 测试设计 → 编码 → 评审 → 交付。PM 会根据任务的体量，从这条流水线中挑出合适的那一段。
- **强制评审** —— 任何代码、计划、API 或文档，在其配对评审者给出 PASS 之前都不会发布。修 Bug 必须先给出根因陈述，并补一条"先失败"的回归测试；宣称"完成"必须附上本轮新鲜的命令输出证据。
- **上下文保护** —— PM 在结构上就无法调用 `Read` / `Write` / `Bash`。它只看到子 agent 的简短摘要，因此稀缺的上下文窗口被留给决策，而不是文件内容。
- **零依赖、零构建步骤** —— 整个插件就是纯 Markdown（skills + agent 定义）加上 bash hooks。没有 `npm install`，没有编译，没有运行时。克隆下来就能跑。

---

## 📦 安装

### 方式 1 —— `git clone`（推荐）

```bash
git clone https://github.com/Qume2005/development-team.git ~/.claude/skills/development-team
chmod +x ~/.claude/skills/development-team/hooks/*
```

两条命令，没有构建步骤，不用配置。

### 方式 2 —— 社区市场（尚未上线）

```bash
/plugin install development-team@claude-community
```

> **注意：** 市场列表还没上线。在那之前，请用方式 1。

### 激活

安装后**没有 slash command**，也不用再跑任何东西。在任意项目里开启一个 Claude Code 会话，`SessionStart` hook 会自动注入引导上下文。Agent 会加载 PM skill 并进入项目经理工作模式 —— 你只需陈述一个目标。

### 卸载

```bash
rm -rf ~/.claude/skills/development-team
```

可选地清理注册表：编辑 `~/.claude/plugins/installed_plugins.json`，移除 `"development-team@local"` 这一块（保持 JSON 有效 —— 别留尾逗号）。`settings.json` 不用改。重启 Claude Code（或 `/clear`），这样下一次会话就不会再自动激活这个团队。

---

## 🚀 使用

装好之后，你唯一要做的就是**用一句话陈述一个目标**，然后放手。PM 会按任务体量安排工作流、调度合适的角色，并对每个交付物把关。

### 大任务 → 全流水线

```
> Build a user authentication system with JWT and OAuth2.

# PM 会：
#  1.（可选地）调度 Intern/Explore 去摸清代码库
#  2. 提出一个 Full System Development 工作流
#     （产品 → 架构 → 规划 → API → 测试设计 → 编码 → 评审 → 交付）
#  3. 等你批准，然后开跑 —— 相互独立的生产者并行执行，
#     每个交付物都由配对评审者把关（最多 3 轮）
```

### 小任务 → 快速修复

```
> Fix the typo on the login page.

# PM 选一条 Quick Fix 工作流：
#  Code Developer → Code Reviewer → 交付
# （修 Bug 依然要求：根因陈述 + 先失败的回归测试）
```

在这两种情况下，每个交付物都必须通过配对评审者的关卡，并附上新鲜的验证证据。中间产物和最终产物都落在该项目的 `.claude/development-team/<role>/` 目录下，按角色扁平化组织。

---

## 与 Claude Code 内置 plan mode 的关系

Claude Code 自带一个内置的 **plan mode**（先调研，再提出计划，然后请用户批准后才执行）。本插件**补充并增强**了 plan mode —— 它不与 plan mode 对抗。`EnterPlanMode` / `ExitPlanMode` 仍然是审批通道，`AskUserQuestion` 仍然是 PM 在提出方案之前澄清含糊请求的方式。

改变的是**谁来撰写计划、谁来搜索代码库**：

- 计划由 **Task Planner** 角色（`development-team:planner`）撰写，并由 **Task Reviewer** 把关 —— PM 自己从不写计划文件，且一份计划在通过评审（PASS）之前不会被呈交审批。
- 大范围的代码库搜索走 **`development-team:explore`**，而不是内置的 `Explore` agent。
- 每一个生产交付物依然要经过它配对的评审者（PASS/FAIL）。

当内置的 plan mode 工作流与本插件的工作流不一致时，**本插件的工作流优先。** Plan mode 是呈现与审批的界面；dev-team 的调度链负责规划、搜索和评审。

---

## ✨ 功能特性

| 功能 | 它给你带来什么 |
|---------|-------------------|
| **20 个专门角色** | 13 个生产者（PM、Intern、Code Developer、Task Planner、Architecture Designer、Product Designer、API Designer、Test Designer、Document Writer、DevOps Engineer、Data Engineer、Migrator、Explore）+ 7 个评审者。每个角色都是原生 Claude Code 插件 agent，拥有自己独门的手艺和工具列表。 |
| **强制配对评审** | 每个交付物都流向它配对的评审者。PASS/FAIL，最多 3 轮。FAIL 会把工作退回修改；只有拿到 PASS，PM 才会把这个产物当作可交付物。 |
| **TDD 纪律** | Test Designer 在代码动笔**之前**就设计好集成测试和系统测试；Code Developer 先写单元测试（红 → 绿），再对照预先设计好的测试去实现。 |
| **验证关卡** | 没有新鲜的、本轮命令输出作为证据，就不会有"已完成 / 通过 / 修复了"的结论。陈旧的运行结果、"应该会过"、以及"只断言不举证"在评审者这里默认就是 FAIL。 |
| **事件驱动、非阻塞调度** | 相互独立的子任务被并行调度。PM 是一个事件驱动的调度器：每一次完成、每一次评审 PASS，都是一个事件，会解锁下一批有依赖关系的工作。 |
| **用 Hook 强制限制 PM 的工具** | PM 的工具限制由 hook 在**结构上**强制执行，而不是靠"自觉" —— PM 字面上就无法调用 `Read`、`Write`、`Edit`、`Bash`、`Glob`、`Grep`、`WebSearch`、`LSP` 或 `NotebookEdit`。子 agent 不受影响。 |
| **防空转的监督式轮询** | 一个 `Stop` hook 阻止 PM 在挂起的工作上悄悄空转：如果没有任何东西会自动恢复会话（没有后台任务、没有有效的监督式 cron），这次停止会被 block，PM 必须搭起一套"可解释的轮询"。 |
| **零依赖** | 纯 Markdown + bash hooks。没有构建步骤，除了 `chmod +x` 之外没有安装步骤。bash 能跑的地方它就能跑。 |

---

## 🧠 工作原理

### PM 循环

```
1. 界定范围    — PM（可选地）调度 Intern/Explore 去读请求，回报一份 3–5 行的摘要
2. 提出方案    — PM 设计一条与任务体量匹配的工作流，呈给用户审批
3. 调度        — PM 调度生产者（非阻塞、事件驱动）；相互独立的工作并行执行
4. 评审关卡    — 每个生产者的交付物流向它配对的评审者（PASS/FAIL，最多 3 轮）
5. 交付        — 一旦所有关卡都 PASS 且附上新鲜的验证证据，PM 就交付给用户
```

### 两级信息访问

系统有意把信息访问分成两个层级：

| 层级 | 角色 | 能读什么 |
|------|------|----------|
| **Tier 1** | Project Manager | **只**能看用户对话 + 子 agent 的返回摘要（3–5 行）。PM 从不读文件。当它需要弄懂某件事时，就调度 Intern 去读并回报。 |
| **Tier 2** | 其他所有人（Intern、所有生产者、所有评审者） | 它们需要什么就能读什么 —— 源码、配置、交付文档、论文。它们的约束是**任务范围**（约 1 个模块 / 2–3 个文件），而不是访问权。 |

这就是"上下文保护"在实践中的含义：PM 的上下文窗口被预留给决策，而干活的人在聚焦的范围内自由读取。

### 生产者 → 评审者 流水线

角色之间的上下文以**磁盘上的 Markdown 交付文档**形式流动，写在 `.claude/development-team/<role>/` 下。每一阶段的输出文档就是下一阶段的输入。PM 从不读这些文档 —— 它只跟踪它们的路径，并吸收评审者的结论。

```
                        ┌─────────────────────────────────────────────┐
                        │              Project Manager                 │
                        │  界定 → 提出 → 调度 → 决策                    │
                        │  （只读摘要，从不读文件）                       │
                        └─────────────┬───────────────────┬────────────┘
                                      │ 调度              │ 调度
                                      ▼                   ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │   Intern /   │   │    Product   │   │ Architecture │   │ Task Planner │
   │   Explore    │   │   Designer   │   │   Designer   │   │              │
   │ (读/画图)    │   │      │       │   │      │       │   │      │       │
   └──────────────┘   │      ▼       │   │      ▼       │   │      ▼       │
                 ┌────┴──────────────┴┐  ┌┴──────────────┴┐  ┌┴──────────────┐
                 │  Product Reviewer  │  │ Arch. Reviewer  │  │ Task Reviewer │
                 │      (PASS?)       │  │    (PASS?)      │  │    (PASS?)    │
                 └─────────┬──────────┘  └────────┬────────┘  └───────┬───────┘
                           │                      │                   │
                           └──────────┬───────────┴───────────────────┘
                                      ▼
                          ┌───────────────────────┐    ┌───────────────────────┐
                          │     API Designer      │───▶│     API Reviewer       │
                          └───────────┬───────────┘    └───────────┬───────────┘
                                      ▼ (TDD：测试先行)
                          ┌───────────────────────┐    ┌───────────────────────┐
                          │     Test Designer     │───▶│ Test Design Reviewer   │
                          └───────────┬───────────┘    └───────────┬───────────┘
                                      ▼                            │ PASS
                          ┌───────────────────────┐    ┌───────────────────────┐
                          │     Code Developer    │───▶│     Code Reviewer       │
                          └───────────┬───────────┘    └───────────┬───────────┘
                                      ▼                            │ PASS
                                      ▼                            ▼
                          ┌──────────────────────────────────────────────────┐
                          │      验证关卡（新鲜证据）                          │
                          └──────────────────────────┬───────────────────────┘
                                                     ▼
                                          ┌────────────────────┐
                                          │   交付给用户         │
                                          └────────────────────┘
```

> PM 从来不是管道本身。磁盘上的文档负责在角色之间传递上下文。PM 只跟踪路径、吸收结论。

---

## 👥 角色（共 20 个）

一共有 **20 个角色**：其中 19 个是 `agents/` 下的原生 Claude Code 插件 agent 文件，外加 **Project Manager**，它是 `skills/pm` skill（不是一个 agent 文件）。每个角色都通过 `subagent_type: development-team:<role>` 来调度。

### 生产者（13 个）

| 角色 | 产出 | 工具 |
|------|----------|-------|
| **Project Manager**（`skills/pm`，不是 agent 文件） | 界定范围、提出工作流、调度、决策 —— 自己从不产出交付物 | *（结构上受限 —— 见 [Hooks](#️-hooks)）* |
| **Intern** | 杂活 + PM 的阅读者：清理、归档、文件操作、定向阅读与摘要 | `Read, Write, Edit, Bash` |
| **Code Developer**（`coder`） | 单个模块的应用代码 + 单元测试；运行所有测试；确认通过 | `Read, Write, Edit, Bash, LSP, WebSearch` |
| **Task Planner**（`planner`） | 执行计划：把工作拆成单模块子任务，并带显式的依赖边 | `Read, Write, WebSearch` |
| **Architecture Designer**（`architect`） | 系统架构：模块拆分、技术选型、依赖图分层、系统测试范围 | `Read, Write, WebSearch` |
| **Product Designer**（`product-designer`） | 产品规格：用户画像、用户故事、功能优先级、成功标准 | `Read, Write, WebSearch` |
| **API Designer**（`api-designer`） | API、接口与契约（契约先行、自顶向下） | `Read, Write, WebSearch` |
| **Test Designer**（`test-designer`） | 集成测试与系统测试，在编码之前设计（TDD） | `Read, Write, Edit, Bash` |
| **Document Writer**（`doc-writer`） | 文档、文章、规格、指南、README | `Read, Write, Edit, WebSearch` |
| **DevOps Engineer**（`devops-engineer`） | 基础设施即代码、CI/CD 流水线、构建配置、容器、部署脚本、可观测性接线 | `Read, Write, Edit, Bash, WebSearch` |
| **Data Engineer**（`data-engineer`） | DB schema 变更、迁移、回填、种子数据；schema 演进纪律（扩展→收缩，可回滚） | `Read, Write, Edit, Bash, LSP` |
| **Migrator**（`migrator`） | 全仓库范围内的机械式改动（codemod、批量重命名、弃用清理）；豁免于"单模块"规则 | `Read, Write, Edit, Bash, LSP` |
| **Explore**（`explore`） | 大范围扇出式代码搜索与映射 —— "X 在哪"，触点枚举。对代码只读；写一份映射文档；无评审者 | `Read, Bash, Write` |

### 评审者（7 个）

每个评审者都是其列中那一类产物的 PASS/FAIL 关卡。一次 FAIL 就会停止评审，把工作退回修改。

| 评审者 | 把什么关 |
|----------|---------------|
| **Product Reviewer**（`product-reviewer`） | 产品设计 —— 用户价值、完整性、优先级 |
| **Architecture Reviewer**（`architect-reviewer`） | 架构设计 —— 模块化、可扩展性、可行性 |
| **Task Reviewer**（`task-reviewer`） | 执行计划 —— 可行性、范围、拆分质量 |
| **API Reviewer**（`api-reviewer`） | API —— 正确性、一致性、易用性 |
| **Test Design Reviewer**（`test-design-reviewer`） | 测试设计 —— 完整性、正确性、边界情况 |
| **Code Reviewer**（`code-reviewer`） | 代码 + 单元测试（也覆盖 DevOps/Data/Migrator 的产出）—— bug、覆盖率、可维护性、TDD 合规、根因与验证证据关卡 |
| **Document Reviewer**（`doc-reviewer`） | 文档 —— 清晰度、准确性、完整性；对 skill/规则改动也强制执行 `writing-skills` 的"基线失败"关卡 |

> **关于 PM：** PM 是唯一的协调角色。它不写代码、不读文件、不跑命令 —— 这既是事实，也是它准确的职责范围。这个团队的价值来自另外 12 个生产者各自独占自己的手艺，以及 7 个评审者各自把守一道关卡。

---

## 🛠️ Skills（共 9 个）

Skills 是可复用的**方法论** —— 在某一纪律派上用场的那一刻，它是权威的"怎么做"。PM（以及相关的子 agent）会按上下文调用它们。它们*不会*在启动时加载，也*不会*取代角色表。

| Skill | 何时触发 | 一句话用途 |
|-------|---------------|------------------|
| **`development-team`** | 每次会话开始时自动触发（通过 SessionStart hook） | 共享的系统规则 —— 交付目录、评审协议、角色表、权限矩阵。强制加载的引导 skill。 |
| **`pm`** | 会话开始时由 agent 加载（在 `development-team` 之后） | PM 专属规则：核心操作循环、非阻塞调度、验证关卡、提交策略。 |
| **`brainstorming`** | PM 在含糊/有创意的任务上提出工作流之前调用 | 把一个开放式请求，在动工之前，变成一份简短、经用户认可的设计。 |
| **`systematic-debugging`** | PM 在每次修 Bug 的调度里引用它；Code Developer 在复现时自我调用 | 在任何修复之前，强制根因调查（复现 → 隔离 → 根因 → 最小修复 → 验证）。 |
| **`verification-before-completion`** | 每个生产者在宣称完成之前；Code Reviewer 作为硬性 PASS/FAIL 关卡 | 在任何"已完成 / 通过 / 修复了"的结论之前，要求新鲜的验证证据（跑命令 → 读输出 → 确认）。 |
| **`branch-finishing`** | PM 在任务完成、分支需要收尾时调用 | 在交接或合并之前，把功能分支带到一个可合并的状态（测试全绿、已 rebase、可提 PR）。 |
| **`using-git-worktrees`** | PM 在并行 / 高风险 / 大量改动文件的工作之前调用 | 把并行的多条工作流隔离到各自的 git worktree 里，避免并发分支互相踩。 |
| **`supervisory-polling`** | PM 在被 block、正打算设置一个轮询 cron 的那一刻调用 | 让一个轮询 cron 去**监督**（检查 → 升级），而不是悄悄地重新装弹。 |
| **`writing-skills`** | PM 在调度任何"新增 / 改进 skill 或 agent 规则"的任务之前调用 | 用 TDD-for-docs 的方式编写 skills/规则 —— 先有基线失败产物，再写那条能堵住它的最小文档。 |

---

## ⚙️ Hooks

这个插件的纪律由 bash hooks 在**结构上**强制执行，而不是靠"自觉"。Hooks 注册在 [`hooks/hooks.json`](hooks/hooks.json) 里。所有 hook 脚本都通过 [`hooks/run-hook.cmd`](hooks/run-hook.cmd) 运行，这是一个跨平台的 polyglot 启动器（Unix 上用 bash；Windows 上它会去定位 Git-for-Windows 的 bash）。已注册的事件：

| 事件（matcher） | 脚本 | 它做什么 |
|-----------------|--------|--------------|
| **`SessionStart`** (`startup\|clear\|compact`) | `session-start` | 清除所有按会话生效的标记，然后注入引导上下文。**团队就是这么激活的** —— 没有 slash command。会话开始时 PM skill 还没加载，所以所有工作工具都会被 block，直到 agent 通过 Skill 工具加载 `development-team:pm` 和 `development-team`。 |
| **`PreToolUse`** (`Skill`) | `pre-skill-use` | 当 `development-team:pm` 被加载时，创建 `PM_LOADED` 和 `PM_RESTRICTED` 标记。始终放行这次 Skill 调用。 |
| **`PreToolUse`** (`Agent`) | `pre-agent-use` | 给活动子 agent 计数器加一（每次调度对应一个标记文件）。始终放行这次 Agent 调用。 |
| **`PreToolUse`** (`Read\|Bash\|Write\|Edit\|Glob\|Grep\|WebSearch\|LSP\|NotebookEdit`) | `pre-tool-use` | **对 PM 的结构性工具限制。** 识别调用方：任何子 agent（前台或后台，靠非空的 `agent_id`/`agent_type` 判定）一律放行；根/PM agent 在设置了 `PM_RESTRICTED` 时、或在缺 `PM_LOADED` 时（引导态）被 block。检查时优先用 `jq` 解析 JSON，没有 `jq` 时回退到 `grep`/`sed`，所以在最小镜像上也能工作。 |
| **`PostToolUse`** (`Agent`) | `post-agent-use` | **空转路由。** 计数器减一以前住在这里，但对*后台*子 agent 来说，Agent 工具会立即返回而子 agent 还在跑，所以在这里减一会在运行中途把计数器抽干。减一现在挪到了 `SubagentStop`。这个脚本只是为了保住 matcher 有效而保留。 |
| **`SubagentStop`**（全部） | `subagent-stop` | 当一个子 agent *真正*结束时，给活动子 agent 计数器减一 —— 对前台和后台调度都正确（后台子 agent 整段运行期间，活动计数器始终 > 0）。 |
| **`Stop`**（全部） | `stop` | **防空转 / 可解释轮询。** 如果 PM 还有挂起的 todo，且没有任何东西会自动恢复会话（没有在途的后台任务、没有"带非平凡 prompt 且下一次触发间隔有上限"的有效监督式 cron），这次停止会被 **block**，PM 被告知去创建一个可解释的轮询 cron。带有一个防循环兜底（`stop_hook_active`）和对 `session_id` 的路径穿越防护。 |

> **未注册（别和生效的 hook 混淆）：**
> - 不存在 `commands/` 目录 —— **没有 slash command**。激活完全靠 SessionStart hook 加上强制自动触发的 `development-team` skill。
> - `hooks/test-stop.sh` 是 Stop hook 的**干跑测试驱动**（19 个用例）。它没有在 `hooks.json` 里注册。

### jq 是可选的

每一个读 JSON 的 hook 在有 `jq` 时优先用 `jq`，否则回退到 `grep`/`sed`，所以这个插件在最小 Linux 镜像和没装 `jq` 的全新 macOS 上都能跑。

---

## ❓ 常见问题与排错

### "我所有工具都被 block 了！"

这在**会话开始时是预期的**。SessionStart hook 注入了引导上下文，但 PM skill 还没加载，所以 `pre-tool-use` 会 block 掉 `Read`/`Bash`/`Write` 等，并给 agent 一条消息，让它先用 Skill 工具加载 PM skill：

```
development-team active but PM skills not loaded.
Invoke via Skill tool FIRST:
  1) development-team:pm
  2) development-team
Then retry.
```

一旦 agent 加载了 `development-team:pm`，`pre-skill-use` hook 就会设置 `PM_LOADED` 和 `PM_RESTRICTED` 标记。从那以后 PM 是被有意限制的（它改为调度子 agent），而子 agent 不受限。

### "`.claude/development-team/` 是从哪儿冒出来的？"

那个目录装的是**内部交付文档** —— 各个角色写给彼此的 Markdown 交接件（计划、设计、评审反馈、映射图）。它在首次使用时创建，且被 **gitignore** 掉了（见 [`.gitignore`](.gitignore)：`.claude/`）。删除它是安全的；它既不属于插件，也不属于你的源码树。

### Windows / 跨平台

Hooks 是 bash 脚本。在 Windows 上，它们通过 [`hooks/run-hook.cmd`](hooks/run-hook.cmd) 运行 —— 后者会定位 Git-for-Windows 的 bash（或 `PATH` 上的 `bash`）并转交给它。如果找不到 bash，启动器会静默退出 —— 插件照样加载，只是跳过了 SessionStart 的上下文注入（在有 bash 的地方，PM 的工具限制 hook 照常生效）。macOS 和 Linux 原生可用。

### 需要 `jq` 吗？

不需要。每个读 JSON 的 hook 在有 `jq` 时优先用 `jq`，否则回退到 `grep`/`sed`。插件在没装 `jq` 的最小镜像上也能跑。

### 怎么新增一个角色或 skill？

编写或编辑一个 skill 或 agent 规则，遵循 **`writing-skills`** 方法论（TDD-for-docs）：先产出一份基线失败产物，再写那条能堵住该失败的最小文档，最后做一次堵漏重测。完整方法请调用 `development-team:writing-skills`。Document Reviewer 会把"基线失败"作为 PASS/FAIL 关卡强制执行。

---

## 📐 项目结构

```
development-team/
├── .claude-plugin/
│   └── plugin.json                  # 插件清单（名称、版本、作者、协议、关键词）
├── agents/                          # 19 个原生 Claude Code 插件 agent（扁平的 .md 文件）
│   ├── intern.md
│   ├── coder.md
│   ├── planner.md
│   ├── architect.md
│   ├── product-designer.md
│   ├── api-designer.md
│   ├── test-designer.md
│   ├── doc-writer.md
│   ├── devops-engineer.md
│   ├── data-engineer.md
│   ├── migrator.md
│   ├── explore.md
│   ├── task-reviewer.md
│   ├── api-reviewer.md
│   ├── architect-reviewer.md
│   ├── product-reviewer.md
│   ├── test-design-reviewer.md
│   ├── code-reviewer.md
│   └── doc-reviewer.md
├── skills/                          # 9 个 skills（每个是一个含 SKILL.md 的目录）
│   ├── development-team/            #   共享系统规则 + 引导（自动触发）
│   │   ├── SKILL.md
│   │   └── bootstrap.md
│   ├── pm/                          #   PM 专属规则（第 20 个角色）
│   ├── brainstorming/
│   ├── systematic-debugging/
│   ├── verification-before-completion/
│   ├── branch-finishing/
│   ├── using-git-worktrees/
│   ├── supervisory-polling/
│   └── writing-skills/
├── hooks/
│   ├── hooks.json                   # Hook 注册（SessionStart, PreToolUse, PostToolUse, SubagentStop, Stop）
│   ├── run-hook.cmd                 # 跨平台启动器（bash polyglot）
│   ├── session-start                # SessionStart：清标记 + 注入引导
│   ├── pre-skill-use                # PreToolUse:Skill：设置 PM_LOADED / PM_RESTRICTED
│   ├── pre-agent-use                # PreToolUse:Agent：给活动子 agent 计数器加一
│   ├── pre-tool-use                 # PreToolUse:Read|Bash|...：强制 PM 工具限制
│   ├── post-agent-use               # PostToolUse:Agent：空转路由（减一已挪到 SubagentStop）
│   ├── subagent-stop                # SubagentStop：给活动子 agent 计数器减一
│   ├── stop                         # Stop：防空转 / 可解释轮询强制
│   └── test-stop.sh                 # Stop hook 的干跑测试驱动（未注册）
├── .gitignore                       # 忽略 .claude/（交付文档）、skills-lock.json、编辑器目录
├── LICENSE                          # MIT
├── README.md                        # 本文件（英文，主版本）
└── README-CN.md                     # 简体中文镜像
```

**计数：** 19 个 agent 文件（`agents/*.md`）+ PM skill（`skills/pm`）= **20 个角色**。`skills/` 下 9 个 skill 目录。7 个已注册的 hook 脚本（外加 `run-hook.cmd` 启动器和 `test-stop.sh` 测试驱动）。没有 `commands/` 目录。

---

## 🤝 贡献

这是一个个人项目，目前由单人维护。欢迎通过 [GitHub Issues](https://github.com/Qume2005/development-team/issues) 提建议和报 bug；也欢迎 pull request。

> `CONTRIBUTING.md` 是未来的后续工作，不在本 README 范围内。仓库里目前没有 banner/logo 图片资源 —— 如果提供了，以后可以加上（不要凭空编造图片路径）。

---

## License

[MIT License](LICENSE) © 2025 Qume

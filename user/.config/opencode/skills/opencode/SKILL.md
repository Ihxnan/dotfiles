---
name: opencode
description: 将编码任务委托给OpenCode CLI代理，用于功能实现、代码重构、PR审查和长时间自动会话。需要提前安装并认证OpenCode CLI。
version: 1.3.0
---

# OpenCode CLI

使用 [OpenCode](https://opencode.ai) 作为自动编码助手。OpenCode是一个不绑定服务商的开源AI编码代理，提供终端界面(TUI)和命令行界面(CLI)。

## 适用场景

* 用户明确要求使用OpenCode
* 需要外部编码代理实现/重构/审查代码
* 需要带进度检查的长时间编码会话
* 需要在独立工作目录中并行执行任务

## 前置条件

* 已安装OpenCode：`npm i -g opencode-ai@latest` 或通过系统包管理器安装
* 已配置认证：`opencode auth login` 或设置服务商环境变量（OPENROUTER_API_KEY等）
* 验证配置：`opencode auth list` 应显示至少一个可用服务商
* 编码任务推荐在Git仓库中执行

## 一次性任务

使用 `opencode run` 执行有明确边界的非交互式任务：

```bash
opencode run '给API调用添加重试逻辑并更新测试'
```

使用 `-f` 附加上下文文件：

```bash
opencode run '审查此配置的安全问题' -f config.yaml -f .env.example
```

使用 `--thinking` 显示模型的思考过程：

```bash
opencode run '调试CI中测试失败的原因' --thinking
```

强制使用指定模型：

```bash
opencode run '重构认证模块' --model openrouter/anthropic/claude-sonnet-4
```

## 交互式会话（TUI）

对于需要多次交互的迭代工作，可以启动TUI界面：

```bash
opencode
```

### TUI快捷键

| 按键 | 功能 |
|-----|--------|
| `Enter` | 提交消息 |
| `Tab` | 切换代理（构建/规划） |
| `Ctrl+P` | 打开命令面板 |
| `Ctrl+X L` | 切换会话 |
| `Ctrl+X M` | 切换模型 |
| `Ctrl+X N` | 新建会话 |
| `Ctrl+X E` | 打开编辑器 |
| `Ctrl+C` | 退出OpenCode |

### 恢复会话

```bash
opencode -c           # 继续上次会话
opencode -s ses_abc123 # 恢复指定会话
```

## 常用参数

| 参数 | 用途 |
|------|-----|
| `run '提示词'` | 一次性执行任务后退出 |
| `--continue` / `-c` | 继续上一次OpenCode会话 |
| `--session <id>` / `-s` | 继续指定会话 |
| `--agent <name>` | 选择OpenCode代理（build或plan） |
| `--model 服务商/模型` | 强制使用指定模型 |
| `--format json` | 机器可读输出/事件格式 |
| `--file <路径>` / `-f` | 附加文件到消息中 |
| `--thinking` | 显示模型思考过程 |
| `--variant <级别>` | 推理强度（high、max、minimal） |
| `--title <名称>` | 为会话命名 |

## 使用流程

1. 验证工具就绪：
   ```bash
   opencode --version
   opencode auth list
   ```
2. 边界明确的任务使用 `opencode run '...'`
3. 迭代任务启动交互式TUI：`opencode`
4. 使用 `Ctrl+C` 退出交互式会话
5. 向用户总结文件变更、测试结果和后续步骤

## PR审查工作流

OpenCode内置PR命令：

```bash
opencode pr 42
```

或在临时克隆中隔离审查：

```bash
REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && opencode run '审查此PR与main分支的差异，报告bug、安全风险、测试缺口和风格问题。'
```

## 并行工作模式

使用独立工作目录避免冲突：

```bash
opencode run '修复#101问题并提交' &   # 在workdir /tmp/issue-101中运行
opencode run '添加解析器回归测试并提交' &  # 在workdir /tmp/issue-102中运行
```

## 会话与成本管理

列出历史会话：

```bash
opencode session list
```

查看token使用量和成本：

```bash
opencode stats
opencode stats --days 7 --models anthropic/claude-sonnet-4
```

## 验证

冒烟测试：

```bash
opencode run '严格返回：OPENCODE_SMOKE_OK'
```

成功标准：
* 输出包含 `OPENCODE_SMOKE_OK`
* 命令退出无服务商/模型错误
* 编码任务：预期文件已更改且测试通过

## 使用规则

1. 一次性任务优先使用 `opencode run` — 更简单
2. 仅当需要迭代时使用交互式TUI模式
3. 始终将OpenCode会话限定在单个仓库/工作目录中
4. 报告具体的任务结果（更改的文件、测试情况、剩余风险）
5. 使用 `Ctrl+C` 退出交互式会话，不要使用 `/exit`

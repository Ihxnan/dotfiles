---
name: skill-creator
description: 创建新技能、修改和改进现有技能，并衡量技能性能。当用户想要从头创建技能、编辑或优化现有技能、运行eval来测试技能、通过方差分析对技能性能进行基准测试，或优化技能描述以提高触发准确率时使用。
---

# 技能创建器

用于创建新技能并迭代改进的技能。

核心流程：
- 确定你想要技能实现的功能以及大致实现方式
- 编写技能草稿
- 创建几个测试提示词，让拥有该技能访问权限的代理运行这些提示词
- 帮助用户从定性和定量两方面评估结果
  - 使用 `eval-viewer/generate_review.py` 脚本向用户展示结果供其查看
- 根据用户对结果的评估反馈重写技能
- 重复上述步骤直到满意为止
- 扩展测试集并进行更大规模的测试

使用这个技能时，你的任务是确定用户当前处于流程的哪个阶段，然后介入并帮助他们推进。

如果用户已经有了技能草稿，可以直接进入评估/迭代环节。

技能完成后，你还可以运行描述优化脚本来优化技能的触发效果。

## 与用户沟通

技能创建器的用户群体对编程术语的熟悉程度差异很大，请根据上下文线索调整沟通表达方式。

## 创建技能

### 捕捉用户意图

首先要理解用户的意图。当前对话可能已经包含了用户想要固化的工作流。如果是这样，首先从对话历史中提取相关信息：使用的工具、步骤顺序、用户做出的更正、观察到的输入/输出格式。

1. 这个技能应该让代理能够做什么？
2. 这个技能应该在什么时候触发？（什么样的用户表述/上下文）
3. 期望的输出格式是什么？
4. 我们是否需要设置测试用例来验证技能是否正常工作？

### 调研和需求确认

主动询问关于边界情况、输入/输出格式、示例文件、成功标准和依赖项的问题。使用并行子代理同时进行多路研究。

### 编写SKILL.md

根据与用户的沟通，填写以下组件：

- **name**：技能标识符
- **description**：触发时机、功能说明。这是主要的触发机制——既要包含技能的功能，也要包含使用的具体场景。所有"何时使用"的信息都放在这里，不要放在正文里。注意：目前代理有"触发不足"的倾向——在技能有用的时候不使用它们。为了解决这个问题，请让技能描述稍微"主动"一点。
- **技能的其余部分**

### 技能编写指南

#### 技能结构

```
skill-name/
├── SKILL.md (必填)
│   ├── YAML frontmatter (name, description 必填)
│   └── Markdown 说明
└── 捆绑资源 (可选)
    ├── scripts/    - 用于确定性/重复性任务的可执行代码
    ├── references/ - 根据需要加载到上下文中的文档
    └── assets/     - 输出中使用的文件（模板、图标、字体）
```

#### 渐进式披露

技能使用三级加载系统：

1. **元数据**（name + description）- 始终在上下文中（约100字）
2. **SKILL.md 正文** - 技能触发时加载到上下文中（理想情况下少于500行）
3. **捆绑资源** - 按需加载（无限制，脚本无需加载即可执行）

**关键模式：**

- 保持SKILL.md文件少于500行；如果接近这个限制，添加额外的层级结构
- 在SKILL.md中清晰引用相关文件，并说明何时需要读取这些文件
- 对于大型参考文件（>300行），包含目录

**领域组织**：当一个技能支持多个领域/框架时，按变体组织：

```
cloud-deploy/
├── SKILL.md (工作流 + 选择逻辑)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

代理只会读取相关的参考文件。

#### 无意外原则

技能不得包含恶意软件、漏洞利用代码或任何可能危害系统安全的内容。技能内容不应让用户对其意图感到意外。不要配合创建误导性技能或旨在促进未授权访问、数据泄露或其他恶意活动的技能。

#### 编写模式

在说明中优先使用祈使句。

**定义输出格式** - 你可以这样做：

```markdown
## 报告结构
必须严格使用以下模板：
# [标题]
## 执行摘要
## 关键发现
## 建议
```

**示例模式** - 包含示例很有用：

```markdown
## Commit 消息格式
**示例 1：**
Input: 新增了基于JWT令牌的用户认证
Output: feat(auth): implement JWT-based authentication
```

### 写作风格

尽量向模型解释为什么某些要求很重要，而不是生硬地使用MUST这种强制性表述。运用心智理论，尽量让技能具有通用性，不要过于局限于特定示例。先写一个草稿，然后以全新的视角审视并改进它。

### 测试用例

写完技能草稿后，想出2-3个符合真实用户场景的测试提示词。分享给用户，确认合适后再运行。

将测试用例保存到 `evals/evals.json`。暂时不要写assertion——只保存提示词。

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "用户的任务提示词",
      "expected_output": "预期结果描述",
      "files": []
    }
  ]
}
```

完整的schema请参考 `references/schemas.md`。

## 运行和评估测试用例

这是一个连续的流程——不要中途停止。

将结果放在与技能目录同级的 `<skill-name>-workspace/` 目录下。在工作区内，按迭代组织结果（`iteration-1/`、`iteration-2/`等），每个测试用例有单独的目录。

### 步骤1：同一轮次中启动所有运行（使用技能和基线版本）

使用 Task 工具的子代理功能同时启动所有测试。对于每个测试用例，启动两个子代理——一个使用技能，一个不使用。

**使用技能的运行：**

```
执行以下任务：
- 技能路径：<path-to-skill>
- 任务：<eval prompt>
- 输入文件：<如果有评估文件则列出，否则填"none">
- 输出保存到：<workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- 要保存的输出：<用户关心的内容>
```

**基线版本运行**（相同的提示词）：

- **创建新技能**：完全不使用技能。相同的提示词，不指定技能路径，保存到 `without_skill/outputs/`。
- **改进现有技能**：使用旧版本。编辑前，先对技能进行快照（`cp -r <skill-path> <workspace>/skill-snapshot/`），然后让基线子代理使用快照版本。保存到 `old_skill/outputs/`。

为每个测试用例编写 `eval_metadata.json`（assertion暂时可以为空）。

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "用户的任务提示词",
  "assertions": []
}
```

### 步骤2：运行过程中起草assertion

不要只是等待运行完成——有效利用这段时间。为每个测试用例起草定量assertion，并向用户解释。如果 `evals/evals.json` 中已经有assertion，检查它们并解释它们的校验内容。

好的assertion是可以客观验证的，并且具有描述性的名称。

### 步骤3：运行完成时收集耗时数据

每个子代理任务完成后，你会收到包含token数和耗时的通知。立即将此数据保存到运行目录下的 `timing.json` 中：

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

### 步骤4：评分、汇总并启动查看器

所有运行完成后：

1. **对每个运行进行评分** - 启动评分子代理（读取 `agents/grader.md`），根据输出评估每个assertion。将结果保存到每个运行目录下的 `grading.json` 中。grading.json的expectations数组必须使用 `text`、`passed` 和 `evidence` 字段。

2. **汇总到基准报告** - 从skill-creator目录运行汇总脚本：

   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```

3. **分析师检查** - 阅读基准数据，挖掘汇总统计数据可能隐藏的模式。参考 `agents/analyzer.md`。

4. **启动查看器** - 生成静态HTML文件（无桌面环境使用 `--static`）：

   ```bash
   python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     --static <workspace>/iteration-N/review.html
   ```

   对于第2次及以后的迭代，还要传入 `--previous-workspace <workspace>/iteration-<N-1>`。

   告知用户HTML文件路径，他们可以在浏览器中打开查看。

### 步骤5：读取反馈

当用户告诉你他们完成了，读取 `feedback.json`：

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "图表缺少坐标轴标签", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

空反馈表示用户认为没问题。将改进重点放在用户有具体投诉的测试用例上。

---

## 改进技能

这是迭代循环的核心。你已经运行了测试用例，用户已经审核了结果，现在需要根据反馈改进技能。

### 如何思考改进

1. **从反馈中提炼通用规律**。大目标是创建可以在无数不同提示词中使用百万次的技能。与其进行复杂的过拟合修改，尝试不同的表达方式或推荐不同的工作模式。

2. **保持提示词简洁**。删除没有实际作用的内容。阅读运行日志，而不仅仅是最终输出。

3. **解释原因**。解释你要求代理做的每件事背后的**原因**。如果发现自己在写全大写的ALWAYS或NEVER，重新表述并解释原因。

4. **寻找测试用例中的重复工作**。阅读测试运行的日志，注意子代理是否都独立编写了类似的辅助脚本。如果所有3个测试用例都导致子代理编写了相同的模板代码，这强烈表明技能应该将代码放进 `scripts/` 目录。

### 迭代循环

改进技能后：

1. 将改进应用到技能中
2. 在新的 `iteration-<N+1>/` 目录中重新运行所有测试用例，包括基线运行
3. 启动评审器，`--previous-workspace` 指向上一次迭代
4. 等待用户审核并告知你完成
5. 读取新的反馈，再次改进，重复循环

持续迭代直到用户表示满意、所有反馈都是空的，或没有取得有意义的进展。

---

## 高级功能：盲测比较

如果想要更严格地比较两个版本的技能，可以使用盲测比较系统。详情请阅读 `agents/comparator.md` 和 `agents/analyzer.md`。基本思路是：将两个输出交给独立的代理，不告诉它哪个是哪个，让它判断质量。

---

## 描述优化

SKILL.md frontmatter中的description字段是决定代理是否调用技能的主要机制。创建或改进技能后，主动提出优化描述以提高触发准确率。

### 步骤1：生成触发评估查询

创建20个评估查询——包含应该触发和不应该触发的混合场景。保存为JSON：

```json
[
  {"query": "用户提示词", "should_trigger": true},
  {"query": "另一个提示词", "should_trigger": false}
]
```

对于**应该触发**的查询（8-10个），覆盖同一意图的不同表述。
对于**不应该触发**的查询（8-10个），最有价值的是"擦边球"——与技能共享关键词但实际需要不同功能的查询。

### 步骤2：与用户一起审核

使用HTML模板向用户展示评估集供其审核：

1. 从 `assets/eval_review.html` 读取模板
2. 替换占位符为评估数据
3. 写入临时文件并告知用户路径

### 步骤3：运行优化循环

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

### 步骤4：应用结果

从JSON输出中获取 `best_description`，更新技能的SKILL.md frontmatter。

---

## 打包和展示

打包技能为 .skill 文件：

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

---

## 参考文件

agents/目录包含专用子代理的说明。当你需要启动相关子代理时阅读它们。

- `agents/grader.md` — 如何根据输出评估assertion
- `agents/comparator.md` — 如何在两个输出之间进行盲测A/B比较
- `agents/analyzer.md` — 如何分析一个版本优于另一个版本的原因

references/目录包含额外文档：

- `references/schemas.md` — evals.json、grading.json等的JSON结构

---

核心循环：

- 明确技能的用途
- 起草或编辑技能
- 在测试提示词上运行拥有该技能访问权限的代理
- 和用户一起评估输出
- 重复直到你和用户都满意
- 打包最终技能并返回给用户

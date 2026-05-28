# ai2ide

中文 | [English](README.en.md)

ai2ide 是一个本地工作流/插件，用来让 Codex、Cursor、Claude Code、Trae 等 AI 编程 Agent 通过 JetBrains 官方 MCP Server 使用 IDE 的语义能力。

它不是 GUI 自动化。Agent 不需要像人类一样点击 PyCharm 或 IntelliJ，而是通过 MCP 调用 IDE 暴露的项目索引能力，例如符号信息、文件问题、重构、格式化、运行配置、文件搜索和终端执行。

## 快速开始

这一节是从零开始接入 PyCharm/IntelliJ 项目语义能力的最短路径。

### 1. 启用 JetBrains MCP

1. 用 PyCharm、IntelliJ IDEA、WebStorm、GoLand、Rider、CLion 或其它 JetBrains IDE 2025.2+ 打开你的目标项目。
2. 打开 `Settings | Tools | MCP Server`。
3. 勾选 **Enable MCP Server**。
4. 先不要关闭这个设置页。你会从这里复制 **Stdio Config** 或 **SSE Config**。

### 2. 选择 Stdio 还是 SSE

优先选择 **Stdio**。它会启动 JetBrains 提供的 Java runner，适合 Codex、Claude Desktop、Claude Code、Cursor、Trae 以及大多数本地桌面/CLI Agent。

只有当客户端明确支持 SSE MCP server 时才使用 **SSE**。有些客户端虽然提供 `url` 字段，但实际按 streamable HTTP 处理，不能直接连接 JetBrains 的 `/sse` endpoint。

### 3. 配置你的 Agent

#### Codex

在 JetBrains 设置页点击 **Copy Stdio Config**，然后按下面的结构写入 `~/.codex/config.toml`。

最小示例：

```toml
[mcp_servers.jetbrains]
command = 'D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java.exe'
args = [
  '-classpath',
  '<从 JetBrains 复制出来的 classpath>',
  'com.intellij.mcpserver.stdio.McpStdioRunnerKt'
]
startup_timeout_sec = 30
tool_timeout_sec = 120

[mcp_servers.jetbrains.env]
IJ_MCP_SERVER_PORT = '64342'
```

请使用你自己 IDE 复制出来的 `command`、`args` 和 `IJ_MCP_SERVER_PORT`。完整模板见 `examples/codex-config.toml`。

验证配置：

```powershell
codex mcp list
codex mcp get jetbrains
```

然后重启 Codex，或者开启一个新会话。

#### Cursor

把 JetBrains 复制出来的 **Stdio Config** 写入 Cursor 的 MCP 配置。可以从 `examples/cursor.mcp.json` 开始改：

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "stdio",
      "command": "D:\\APP\\pycharm\\PyCharm 2025.3\\jbr\\bin\\java",
      "args": [
        "-classpath",
        "<从 JetBrains 复制出来的 classpath>",
        "com.intellij.mcpserver.stdio.McpStdioRunnerKt"
      ],
      "env": {
        "IJ_MCP_SERVER_PORT": "64342"
      }
    }
  }
}
```

保存后重启 Cursor。如果你的 Cursor MCP UI 明确支持 SSE，也可以参考 `examples/cursor-sse.mcp.json`。

#### Claude Desktop

使用 `examples/claude-desktop.json` 作为 `claude_desktop_config.json` 的配置形状：

```json
{
  "mcpServers": {
    "jetbrains": {
      "command": "D:\\APP\\pycharm\\PyCharm 2025.3\\jbr\\bin\\java",
      "args": [
        "-classpath",
        "<从 JetBrains 复制出来的 classpath>",
        "com.intellij.mcpserver.stdio.McpStdioRunnerKt"
      ],
      "env": {
        "IJ_MCP_SERVER_PORT": "64342"
      }
    }
  }
}
```

修改后重启 Claude Desktop。

#### Claude Code

如果你的 Claude Code 版本支持用命令注册 MCP，可以使用同样的 Stdio command：

```bash
claude mcp add jetbrains \
  -e IJ_MCP_SERVER_PORT=64342 \
  -- "D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java" \
  -classpath "<从 JetBrains 复制出来的 classpath>" \
  com.intellij.mcpserver.stdio.McpStdioRunnerKt
```

也可以参考 `examples/claude-code.md`。添加后重启 Claude Code。

#### Trae 和其它 MCP 客户端

Trae 以及类似 MCP 客户端通常可以使用和 Cursor 相同的 Stdio JSON 结构。可以从 `examples/trae.mcp.json` 开始，把 Java 路径、classpath 和端口替换成你在 JetBrains IDE 里复制出来的值，然后重启客户端。

### 4. 验证工具是否可用

向 Agent 提问：

```text
列出当前可用的 JetBrains MCP tools，并告诉我 server 是否已连接。
```

预期可以看到类似工具名：

```text
mcp__jetbrains__get_file_problems
mcp__jetbrains__get_symbol_info
mcp__jetbrains__rename_refactoring
mcp__jetbrains__reformat_file
mcp__jetbrains__search_in_files_by_text
```

如果 `resources/list` 为空或提示不支持，不代表失败。JetBrains MCP 主要暴露的是 tools。

### 5. 尝试一个真实 IDE 辅助任务

当工具可见后，可以先问一个只读问题：

```text
使用 JetBrains MCP 检查当前项目，列出当前文件问题，并总结可用的 run configurations。不要修改文件。
```

如果要修改代码，可以明确要求 Agent 使用 ai2ide 工作流：

```text
使用 ai2ide：修改这个 API 前，先用 JetBrains MCP 检查 symbol info 和 file problems，然后做最小安全修改并验证。
```

## 仓库内容

- `skills/ide-assisted-coding/SKILL.md`：Codex skill，定义什么时候用 CLI、什么时候用 JetBrains MCP。
- `scripts/diagnose-ai2ide.ps1`：Windows 只读诊断脚本，用于检查本机配置是否就绪。
- `.codex-plugin/plugin.json`：本地 Codex 插件 manifest。
- `examples/`：Codex、Cursor、Claude Desktop、Claude Code、Trae 等客户端的 MCP 配置模板。

## 环境要求

- JetBrains IDE 2025.2 或更新版本，例如 PyCharm、IntelliJ IDEA、WebStorm、GoLand、Rider、CLion。
- 在 `Settings | Tools | MCP Server` 中启用 JetBrains MCP Server。
- 一个支持 MCP 的 Agent/客户端。
- 一个可信任的本地项目。ai2ide 默认是高信任本地开发模式；JetBrains MCP 可能暴露读文件、写文件、格式化、重构、运行命令或执行 IDE run configuration 的工具。

## Codex 配置

把 JetBrains 复制出来的 Stdio config 写入 `~/.codex/config.toml`：

```toml
[mcp_servers.jetbrains]
command = 'D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java.exe'
args = [
  '-classpath',
  '<从 JetBrains 复制出来的 classpath>',
  'com.intellij.mcpserver.stdio.McpStdioRunnerKt'
]
startup_timeout_sec = 30
tool_timeout_sec = 120

[mcp_servers.jetbrains.env]
IJ_MCP_SERVER_PORT = '64342'
```

请使用你自己复制出来的 `command`、`args` 和 `IJ_MCP_SERVER_PORT`；上面只是 Windows 示例。

验证：

```powershell
codex mcp list
codex mcp get jetbrains
```

新开一个 Codex 会话后，应该能看到类似工具：

- `mcp__jetbrains__get_file_problems`
- `mcp__jetbrains__get_symbol_info`
- `mcp__jetbrains__rename_refactoring`
- `mcp__jetbrains__reformat_file`
- `mcp__jetbrains__search_in_files_by_text`
- `mcp__jetbrains__execute_run_configuration`

JetBrains MCP 可能不支持 `resources/list` 或 `resources/templates/list`。这没关系，真正有用的是 tools。

## 其它 Agent

大多数 MCP 客户端接受下面两种配置形状之一。

Stdio JSON：

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "stdio",
      "command": "D:\\APP\\pycharm\\PyCharm 2025.3\\jbr\\bin\\java",
      "args": [
        "-classpath",
        "<从 JetBrains 复制出来的 classpath>",
        "com.intellij.mcpserver.stdio.McpStdioRunnerKt"
      ],
      "env": {
        "IJ_MCP_SERVER_PORT": "64342"
      }
    }
  }
}
```

SSE JSON：

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "sse",
      "url": "http://localhost:64342/sse",
      "headers": {
        "IJ_MCP_SERVER_PROJECT_PATH": null
      }
    }
  }
}
```

能复制官方配置时，优先使用 JetBrains 设置页复制出来的原始配置。可参考：

- `examples/cursor.mcp.json`
- `examples/claude-desktop.json`
- `examples/claude-code.md`
- `examples/trae.mcp.json`
- `examples/codex-config.toml`

## Agent 工作流

ai2ide 最适合配合下面的纪律使用：

- CLI 负责大范围搜索、读文件、`git diff`、测试和确定性编辑。
- JetBrains MCP 负责 symbol information、IDE inspections、project modules、run configurations、格式化和重构敏感任务。
- 修改 rename、API、imports、框架 wiring、共享 symbol 之前，优先收集 IDE 语义证据。
- 修改后同时用 CLI tests/builds 和 JetBrains file problems 或 build/run tools 验证。
- 最终回复里说明用了哪些 IDE tools，以及验证结果。

## 诊断

运行只读诊断脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/diagnose-ai2ide.ps1
```

JSON 输出：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/diagnose-ai2ide.ps1 -Json
```

这个脚本会检查 Codex、Cursor、Claude、Trae 风格 MCP 配置痕迹，以及 JetBrains IDE 安装情况。它不会修改配置文件。

## 常见问题

- **Codex 说 resources 是空的**：JetBrains MCP 主要暴露 tools，不是 resources。请检查 `mcp__jetbrains__...` 工具。
- **握手失败，出现 `initialize response`**：优先使用 JetBrains 复制出来的 Stdio config，不要优先用 `@jetbrains/mcp-proxy`。
- **SSE URL 在浏览器或 PowerShell 里一直挂起**：SSE 是长连接，请求挂起可能说明 endpoint 是活的。
- **同时打开了多个 JetBrains IDE**：从目标 IDE 复制配置，并保持 `IJ_MCP_SERVER_PORT` 对应目标 IDE。
- **配置后看不到 tools**：重启 Agent/客户端。很多客户端只在进程启动时加载 MCP server。

## 官方参考

- JetBrains IntelliJ IDEA MCP Server: https://www.jetbrains.com/help/idea/mcp-server.html
- JetBrains PyCharm MCP Server: https://www.jetbrains.com/help/pycharm/mcp-server.html
- Cursor MCP docs: https://docs.cursor.com/context/model-context-protocol
- Anthropic MCP docs: https://docs.anthropic.com/en/docs/agents-and-tools/mcp

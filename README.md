# ai2ide

ai2ide is a local workflow/plugin for letting AI coding agents use JetBrains IDE semantic capabilities through the official JetBrains MCP Server.

It is not GUI automation. The agent does not click PyCharm or IntelliJ like a human. Instead, the IDE exposes project-indexed tools such as symbol lookup, file problems, refactoring, formatting, run configurations, file search, and terminal execution over MCP.

## Quick Start

This is the fastest path from zero to an agent that can use PyCharm/IntelliJ project semantics.

### 1. Enable JetBrains MCP

1. Open your target project in PyCharm, IntelliJ IDEA, WebStorm, GoLand, Rider, CLion, or another JetBrains IDE 2025.2+.
2. Open `Settings | Tools | MCP Server`.
3. Check **Enable MCP Server**.
4. Keep the settings page open. You will use either **Copy Stdio Config** or **Copy SSE Config** from this page.

### 2. Choose Stdio or SSE

Prefer **Stdio** for desktop and CLI agents. It launches a JetBrains-provided Java runner and is the most reliable option for Codex, Claude Desktop, Claude Code, Cursor, Trae, and similar local clients.

Use **SSE** only when your client explicitly supports SSE MCP servers. Some clients expose a generic `url` field but treat it as streamable HTTP, which is not the same thing as JetBrains' `/sse` endpoint.

### 3. Configure Your Agent

#### Codex

Copy the JetBrains **Stdio Config**, then adapt it into `~/.codex/config.toml`.

Minimal shape:

```toml
[mcp_servers.jetbrains]
command = 'D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java.exe'
args = [
  '-classpath',
  '<classpath copied from JetBrains>',
  'com.intellij.mcpserver.stdio.McpStdioRunnerKt'
]
startup_timeout_sec = 30
tool_timeout_sec = 120

[mcp_servers.jetbrains.env]
IJ_MCP_SERVER_PORT = '64342'
```

Use your own copied `command`, `args`, and `IJ_MCP_SERVER_PORT`. See `examples/codex-config.toml`.

Verify:

```powershell
codex mcp list
codex mcp get jetbrains
```

Then restart Codex or open a new session.

#### Cursor

Use the copied JetBrains **Stdio Config** in Cursor's MCP config. Start from `examples/cursor.mcp.json`:

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "stdio",
      "command": "D:\\APP\\pycharm\\PyCharm 2025.3\\jbr\\bin\\java",
      "args": [
        "-classpath",
        "<classpath copied from JetBrains>",
        "com.intellij.mcpserver.stdio.McpStdioRunnerKt"
      ],
      "env": {
        "IJ_MCP_SERVER_PORT": "64342"
      }
    }
  }
}
```

Restart Cursor after saving the config. If Cursor's MCP UI explicitly supports SSE, `examples/cursor-sse.mcp.json` is also available.

#### Claude Desktop

Use `examples/claude-desktop.json` as the shape for `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "jetbrains": {
      "command": "D:\\APP\\pycharm\\PyCharm 2025.3\\jbr\\bin\\java",
      "args": [
        "-classpath",
        "<classpath copied from JetBrains>",
        "com.intellij.mcpserver.stdio.McpStdioRunnerKt"
      ],
      "env": {
        "IJ_MCP_SERVER_PORT": "64342"
      }
    }
  }
}
```

Restart Claude Desktop after editing the file.

#### Claude Code

If your Claude Code version supports CLI MCP registration, use the same Stdio command:

```bash
claude mcp add jetbrains \
  -e IJ_MCP_SERVER_PORT=64342 \
  -- "D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java" \
  -classpath "<classpath copied from JetBrains>" \
  com.intellij.mcpserver.stdio.McpStdioRunnerKt
```

See `examples/claude-code.md`. Restart Claude Code after adding the server.

#### Trae and Similar MCP Clients

Use the same Stdio JSON pattern as Cursor. Start from `examples/trae.mcp.json`, replace the Java path, classpath, and port with the values copied from your JetBrains IDE, then restart the client.

### 4. Verify Tools Are Available

Ask the agent:

```text
List the available JetBrains MCP tools and tell me whether the server is connected.
```

Expected tool names include:

```text
mcp__jetbrains__get_file_problems
mcp__jetbrains__get_symbol_info
mcp__jetbrains__rename_refactoring
mcp__jetbrains__reformat_file
mcp__jetbrains__search_in_files_by_text
```

If `resources/list` is empty or unsupported, that is not a failure. JetBrains MCP mainly exposes tools.

### 5. Try a Real IDE-Assisted Task

Once tools are visible, ask something like:

```text
Use JetBrains MCP to inspect this project, list current file problems, and summarize the run configurations. Do not modify files.
```

For code changes, ask the agent to use the ai2ide workflow:

```text
Use ai2ide: before changing this API, inspect symbol info and file problems with JetBrains MCP, then make the smallest safe edit and verify it.
```

## What This Repo Contains

- `skills/ide-assisted-coding/SKILL.md`: Codex skill instructions for deciding when to use CLI tools and when to use JetBrains MCP.
- `scripts/diagnose-ai2ide.ps1`: Read-only Windows diagnostic script for local readiness checks.
- `.codex-plugin/plugin.json`: Local Codex plugin manifest.
- `examples/`: Copyable MCP configuration examples for Codex, Cursor, Claude Desktop/Claude Code, and Trae-style clients.

## Requirements

- JetBrains IDE 2025.2 or newer, such as PyCharm, IntelliJ IDEA, WebStorm, GoLand, Rider, or CLion.
- JetBrains MCP Server enabled in `Settings | Tools | MCP Server`.
- An MCP-capable agent/client.
- A trusted local project. ai2ide assumes high-trust local development; JetBrains MCP can expose tools that read, write, format, refactor, run commands, or execute IDE run configurations.

## Codex Setup

Use the copied JetBrains Stdio config in `~/.codex/config.toml`:

```toml
[mcp_servers.jetbrains]
command = 'D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java.exe'
args = [
  '-classpath',
  '<classpath copied from JetBrains>',
  'com.intellij.mcpserver.stdio.McpStdioRunnerKt'
]
startup_timeout_sec = 30
tool_timeout_sec = 120

[mcp_servers.jetbrains.env]
IJ_MCP_SERVER_PORT = '64342'
```

Use your own copied `command`, `args`, and `IJ_MCP_SERVER_PORT`; the values above are examples from one Windows machine.

Verification:

```powershell
codex mcp list
codex mcp get jetbrains
```

In a fresh Codex session, JetBrains tools should appear with names like:

- `mcp__jetbrains__get_file_problems`
- `mcp__jetbrains__get_symbol_info`
- `mcp__jetbrains__rename_refactoring`
- `mcp__jetbrains__reformat_file`
- `mcp__jetbrains__search_in_files_by_text`
- `mcp__jetbrains__execute_run_configuration`

JetBrains MCP may not support `resources/list` or `resources/templates/list`. That is fine; the useful surface is the tools list.

## Other Agents

Most MCP clients accept one of these shapes:

- Stdio JSON:

```json
{
  "mcpServers": {
    "jetbrains": {
      "type": "stdio",
      "command": "D:\\APP\\pycharm\\PyCharm 2025.3\\jbr\\bin\\java",
      "args": [
        "-classpath",
        "<classpath copied from JetBrains>",
        "com.intellij.mcpserver.stdio.McpStdioRunnerKt"
      ],
      "env": {
        "IJ_MCP_SERVER_PORT": "64342"
      }
    }
  }
}
```

- SSE JSON:

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

Use the exact config copied from JetBrains when possible. See:

- `examples/cursor.mcp.json`
- `examples/claude-desktop.json`
- `examples/claude-code.md`
- `examples/trae.mcp.json`
- `examples/codex-config.toml`

## Agent Workflow

ai2ide is most useful when the agent follows this discipline:

- Use CLI for broad search, file reads, git diff, tests, and deterministic edits.
- Use JetBrains MCP for symbol information, IDE inspections, project modules, run configurations, formatting, and refactor-sensitive work.
- Before risky edits such as rename, API changes, imports, framework wiring, or shared symbols, collect IDE semantic evidence first.
- After edits, verify with CLI tests/builds and, when available, JetBrains file problems or build/run tools.
- In the final response, report which IDE tools were used and what was verified.

## Diagnostics

Run the read-only diagnostic:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/diagnose-ai2ide.ps1
```

JSON output:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/diagnose-ai2ide.ps1 -Json
```

The script checks common local traces for Codex, Cursor, Claude, Trae-style MCP config, and JetBrains IDE installations. It does not edit configuration files.

## Troubleshooting

- **Codex says resources are empty**: JetBrains MCP primarily exposes tools, not resources. Check for `mcp__jetbrains__...` tools.
- **Handshake fails with `initialize response`**: Use the JetBrains-copied Stdio config instead of `@jetbrains/mcp-proxy`, or ensure the proxy uses the correct IDE port.
- **SSE URL hangs in browser or PowerShell**: SSE is a long-lived stream. A hanging request can mean the endpoint is alive.
- **Multiple JetBrains IDEs are open**: Copy config from the target IDE and keep the matching port in `IJ_MCP_SERVER_PORT`.
- **Tools are missing after config changes**: Restart the agent/client. Many clients load MCP servers only at process startup.

## Official References

- JetBrains IntelliJ IDEA MCP Server: https://www.jetbrains.com/help/idea/mcp-server.html
- JetBrains PyCharm MCP Server: https://www.jetbrains.com/help/pycharm/mcp-server.html
- Cursor MCP docs: https://docs.cursor.com/context/model-context-protocol
- Anthropic MCP docs: https://docs.anthropic.com/en/docs/agents-and-tools/mcp

# ai2ide

ai2ide is a local workflow/plugin for letting AI coding agents use JetBrains IDE semantic capabilities through the official JetBrains MCP Server.

It is not GUI automation. The agent does not click PyCharm or IntelliJ like a human. Instead, the IDE exposes project-indexed tools such as symbol lookup, file problems, refactoring, formatting, run configurations, file search, and terminal execution over MCP.

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

## Recommended Setup

1. Open your project in a JetBrains IDE.
2. Go to `Settings | Tools | MCP Server`.
3. Enable the MCP Server.
4. Prefer **Copy Stdio Config** for desktop/CLI agents.
5. Paste/adapt the config for your agent from `examples/`.
6. Restart the agent so it reloads MCP servers.

The Stdio config copied from JetBrains is the most reliable option for current desktop agents. The SSE config is useful for clients that explicitly support SSE. Do not assume a client option named `url` supports SSE; some clients treat it as streamable HTTP instead.

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

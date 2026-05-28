# JetBrains MCP Reference

## V1 Position

ai2ide v1 depends on JetBrains official MCP support. It does not implement GUI automation, a custom JetBrains plugin, a VS Code adapter, or a generic LSP abstraction.

Use JetBrains MCP as the semantic IDE surface and CLI as the high-throughput execution surface. The user has selected a high-trust mode, so IDE MCP tools may be allowed to read, write, format, build, run configurations, and trigger IDE operations when the connected server exposes those tools.

For cross-agent setup, prefer the Stdio config copied from `Settings | Tools | MCP Server`. The Stdio runner uses the JetBrains IDE's `mcpserver-frontend.jar` and `IJ_MCP_SERVER_PORT`. The older `@jetbrains/mcp-proxy` package may not work with newer IDE MCP Server implementations because it expects `/api/mcp/list_tools`, while newer IDE settings expose copied Stdio and SSE configurations directly.

## Official Documentation

- IntelliJ IDEA MCP Server: https://www.jetbrains.com/help/idea/mcp-server.html
- PyCharm MCP Server: https://www.jetbrains.com/help/pycharm/mcp-server.html

As of the v1 plan, JetBrains documents MCP Server support as built into 2025.2+ IDEs and describes Codex integration, brave mode, and tools such as project build, file problem retrieval, symbol information, file reading, and file opening. Use the currently connected MCP tool list as the source of truth at runtime because JetBrains may add, remove, or rename tools.

## Capability Expectations

Expected v1-friendly capabilities:

- Get project or file-level problems from IDE inspections.
- Get symbol information from the project index.
- Build the project or collect build feedback.
- Read or open project files through IDE context.
- Reformat files when the IDE tool is available.
- Run IDE-backed operations when the user has configured a trusted MCP mode.

Do not assume these capabilities exist unless they are visible in the connected MCP tools. If a needed capability is absent, fall back to CLI search, language tools, tests, and static analyzers.

JetBrains MCP may not support `resources/list` or `resources/templates/list`. That does not mean the server is unusable; verify tool availability instead.

## Agent Configuration Shapes

Common Stdio MCP JSON shape:

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

Codex TOML shape:

```toml
[mcp_servers.jetbrains]
command = 'D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java.exe'
args = ['-classpath', '<classpath copied from JetBrains>', 'com.intellij.mcpserver.stdio.McpStdioRunnerKt']

[mcp_servers.jetbrains.env]
IJ_MCP_SERVER_PORT = '64342'
```

SSE shape for clients that explicitly support SSE:

```json
{
  "type": "sse",
  "url": "http://localhost:64342/sse",
  "headers": {
    "IJ_MCP_SERVER_PROJECT_PATH": null
  }
}
```

## Future Extension Candidates

Only consider a custom JetBrains plugin if official MCP does not expose a capability needed by repeated real tasks:

- Find usages and references.
- Go to definition, declaration, or implementation.
- Rename preview with conflict reporting.
- Apply quick fixes.
- Call hierarchy and type hierarchy.
- Debugger breakpoints, stepping, stack frames, and variable inspection.
- Indexing status and wait-for-index behavior.

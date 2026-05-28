# Claude Code MCP Setup

Prefer the JetBrains Stdio config copied from `Settings | Tools | MCP Server`.

One common local setup is:

```bash
claude mcp add jetbrains \
  -e IJ_MCP_SERVER_PORT=64342 \
  -- "D:\APP\pycharm\PyCharm 2025.3\jbr\bin\java" \
  -classpath "PASTE_THE_CLASSPATH_COPIED_FROM_JETBRAINS_HERE" \
  com.intellij.mcpserver.stdio.McpStdioRunnerKt
```

If your Claude Code version expects JSON config instead of CLI registration, use the same shape as `examples/claude-desktop.json`.

Restart Claude Code after adding or changing MCP servers.

# ai2ide Agent Instructions

Use JetBrains MCP when this project is opened in a JetBrains IDE and the `jetbrains` MCP server is available.

- Prefer CLI for broad search, reading many files, git status/diff, tests, and deterministic edits.
- Prefer JetBrains MCP for symbol information, file problems, formatting, run configurations, IDE-aware file search, and refactor-sensitive work.
- Before changing public APIs, shared symbols, imports, framework wiring, or names referenced across files, collect at least one relevant IDE signal when possible.
- After editing, verify with CLI tests/builds and JetBrains file problems or run/build tools when available.
- Treat JetBrains MCP as high trust: it may expose tools that read, write, refactor, run terminal commands, or execute IDE run configurations.
- If JetBrains MCP is unavailable, continue with CLI evidence and state the fallback in the final response.

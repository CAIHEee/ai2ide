---
name: ide-assisted-coding
description: Use JetBrains IDE semantic capabilities while coding in Codex. Use when working on code understanding, edits, refactors, debugging build or test failures, IDE inspection issues, symbol lookup, API changes, formatting, or any task where JetBrains official MCP tools can provide project-indexed context for IntelliJ IDEA, PyCharm, WebStorm, or other JetBrains IDEs.
---

# IDE Assisted Coding

## Overview

Use this skill to combine Codex CLI workflows with JetBrains official MCP tools. Treat CLI as the high-throughput file, diff, and test surface; treat the IDE as the semantic project index for symbols, inspections, formatting, build feedback, and high-trust project operations.

This v1 is intentionally high trust: if JetBrains MCP tools are connected, they may read files, write files, format code, build projects, run configurations, open files, or trigger IDE behavior. Summarize every meaningful write or run in the final response, including verification results.

## Tool Selection

Prefer CLI for:

- Broad text search, file listing, reading many files, and fast project reconnaissance.
- Git status, git diff, patch review, test commands, package scripts, and build scripts.
- Deterministic file edits when the target change is already clear.

Prefer JetBrains MCP for:

- Symbol information, project-indexed code understanding, imports, inferred types, and framework wiring.
- IDE inspections, file problems, formatting, build feedback, and run configuration context.
- Refactors or edits that depend on definitions, references, declarations, implementations, or IDE project model.

If JetBrains MCP is unavailable or lacks a needed capability, continue with CLI, language tooling, tests, and static analyzers. Note the fallback in the final response when it materially affects confidence.

## Coding Workflow

1. Establish project state with CLI: list relevant files, inspect git status when available, and identify existing test/build commands.
2. Before changing public APIs, classes, functions, imports, framework entrypoints, or shared symbols, collect IDE semantic evidence when MCP tools are available.
3. Use IDE MCP signals to narrow the change: symbol info, file problems, build output, formatting expectations, and project model clues.
4. Make the smallest coherent change using the safest available surface. In this high-trust v1, IDE MCP write/refactor/format/run tools are allowed when they fit the task.
5. Verify with CLI tests or build commands. Also use JetBrains MCP inspections/build feedback when available.
6. Report the files changed, IDE-assisted operations used, tests/checks run, and any remaining risk.

## Required Evidence Before Risky Edits

For these tasks, do not edit first if JetBrains MCP is available:

- Rename, move, delete, or signature changes for functions, methods, classes, modules, routes, or components.
- Import, dependency injection, framework configuration, or generated-code interactions.
- Fixes where IDE inspections or type inference may identify the real source better than text search.

Collect at least one relevant IDE signal such as symbol info, file problems, build feedback, formatting, or run configuration context. If the IDE MCP server is not connected, state that and proceed with CLI evidence.

## High-Trust Mode

This plugin assumes the user has opted into a trusted local workflow. JetBrains MCP may expose powerful actions, including file reads/writes, terminal or run configuration execution, build triggers, formatting, and IDE project operations.

Follow these guardrails:

- Keep changes scoped to the user's request and current workspace.
- Check for user changes before overwriting nearby code.
- Prefer visible diff review after IDE-assisted writes or refactors.
- Never claim IDE verification happened unless an IDE MCP tool actually provided that signal.
- Include MCP failures, unavailable tools, or skipped IDE checks in the final response.

## Diagnostics

Use the repository script when the user asks whether ai2ide is ready on their machine:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/diagnose-ai2ide.ps1
```

The script is read-only. It reports OS context, plugin paths, common Codex MCP config locations, JetBrains IDE install hints, and possible MCP-related configuration traces.

## Cross-Agent Setup

For setup or troubleshooting across Codex, Cursor, Claude Desktop, Claude Code, Trae, or similar MCP clients, read the repository root `README.md` and copy/adapt files in `examples/`.

Prefer the Stdio config copied from `Settings | Tools | MCP Server` in JetBrains IDEs. Some clients support the SSE URL from the same settings page, but others interpret URL-based MCP config as streamable HTTP and will not connect correctly to `/sse`.

Do not treat empty MCP resources as failure by itself. JetBrains MCP primarily exposes tools such as `get_file_problems`, `get_symbol_info`, `rename_refactoring`, `reformat_file`, and file search operations.

## Reference

Read `references/jetbrains-mcp.md` when you need the v1 capability assumptions, official documentation links, or the scope boundary between ai2ide, JetBrains MCP, and future custom IDE plugins.

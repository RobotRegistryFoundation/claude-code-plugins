# claude-code-plugins

Claude Code plugin marketplace for the [robot-md](https://robotmd.dev) ecosystem.

## Install

Inside Claude Code (defaults to `--scope user` — the recommended choice):

```
/plugin marketplace add RobotRegistryFoundation/claude-code-plugins
/plugin install robot-md
/reload-plugins
```

For a team-pinned install (`--scope project` on both commands), see the **Phase 1** table in the [robot-md plugin README](https://github.com/RobotRegistryFoundation/robot-md-mcp#claude-code-plugin--the-easiest-path).

After installing, launch Claude Code from a directory that contains a `ROBOT.md` at the root. Phase 2 of the plugin README walks through creating one with `robot-md init` if you don't have one yet.

## Plugins

| Name | Source | What it does |
|---|---|---|
| [`robot-md`](https://github.com/RobotRegistryFoundation/robot-md-mcp) | `robot-md-mcp` | Bundles the `using-robot-md` skill and auto-registers the MCP server for a workspace's `ROBOT.md`. |

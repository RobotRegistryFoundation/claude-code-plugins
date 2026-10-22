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

To add the Bounded Embodiment skill from the same marketplace:

```
/plugin install bounded-embodiment@robotregistryfoundation
/reload-plugins
```

## Plugins

| Name | Source | What it does |
|---|---|---|
| [`robot-md`](https://github.com/RobotRegistryFoundation/robot-md-mcp) | `robot-md-mcp` | Bundles the `using-robot-md` skill and auto-registers the MCP server for a workspace's `ROBOT.md`. |
| [`bounded-embodiment`](plugins/bounded-embodiment) | this repository | Bundles the `bounded-embodiment` skill. It keeps AI-driven motion behind a gate, drafts envelopes for the integrator to decide, rehearses EV-03 and EV-10 in simulation with [bounded-embodiment-kit](https://github.com/RobotRegistryFoundation/bounded-embodiment), and prepares hardware commands for a person at the machine to run. Method v0.1 is a draft for comment, and a verdict is never a certification. |

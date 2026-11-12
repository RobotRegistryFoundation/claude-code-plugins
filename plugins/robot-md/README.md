# robot-md

The robot-md plugin connects a robot to Claude through the `ROBOT.md` at the root of its workspace. It bundles three skills, one command and one MCP server.

| Component | What it does | Canonical source |
|---|---|---|
| `using-robot-md` skill | Installs robot-md, reads the manifest, poses and calibrates the robot | [robot-md-mcp](https://github.com/RobotRegistryFoundation/robot-md-mcp/tree/main/skills/using-robot-md) |
| `bounded-embodiment` skill | Keeps AI-driven motion behind a gate, drafts envelopes, rehearses EV-03 and EV-10 in simulation, reads verdicts honestly | [plugins/bounded-embodiment](../bounded-embodiment/skills/bounded-embodiment) |
| `rrf-registry` skill | Registers the robot, rotates and revokes keys, proves manufacturer identity, emits and submits EU AI Act evidence | this plugin |
| `/robot-md:enable-dispatch` | Writes dispatcher config and bearer tokens without printing the token into the conversation | [robot-md-mcp](https://github.com/RobotRegistryFoundation/robot-md-mcp/tree/main/commands) |
| `robot-md` MCP server | Manifest reads plus motion (`execute_task`, `execute_capability`, `vision_find`, `estop`). `scripts/start-mcp-server.py` finds your installed `robot-md` CLI and runs `robot-md mcp` | [robot-md](https://github.com/RobotRegistryFoundation/robot-md) (PyPI) |

## Install

```
/plugin install robot-md --marketplace RobotRegistryFoundation/claude-code-plugins
```

Then install the CLI the MCP server runs on:

```bash
python3 -m pip install --user 'robot-md[hardware]'
```

Launch Claude Code from a directory with a `ROBOT.md` at its root. If you don't have one, ask Claude to set the robot up; the `using-robot-md` skill walks through `robot-md init`.

## Safety

Declaration doesn't enforce anything. Physical limits are meant to be enforced at Layer 3, in `robot-md-gateway` and the actuator driver behind it, and only for commands that pass through it. The gateway isn't a certified safety function. A Bounded Embodiment verdict is a finding about one run, never a certification, and a simulation verdict is always INCONCLUSIVE for hardware.

## Data

The MCP server runs locally and sends nothing to the Robot Registry Foundation. Registry commands, which the `rrf-registry` skill runs only after you agree, publish a robot record at `rcan.dev/r/<rrn>` under CC0. See the [privacy policy](https://robotmd.dev/privacy/).

## Keeping copies in sync

The `using-robot-md`, `bounded-embodiment` and `enable-dispatch` files, `.mcp.json` and `scripts/start-mcp-server.py` here are copies. Edit the canonical source, then run `scripts/sync-robot-md.sh` from the repository root. CI fails when a copy drifts.

# robot-md (directory version)

The robot-md plugin connects a robot to Claude through the `ROBOT.md` at the root of its workspace. This is the version listed in the Claude plugin directory: three skills and two commands, and no MCP server.

| Component | What it does |
|---|---|
| `using-robot-md` skill | Installs robot-md, reads the manifest, poses and calibrates the robot |
| `bounded-embodiment` skill | Keeps AI-driven motion behind a gate, drafts envelopes, rehearses EV-03 and EV-10 in simulation, reads verdicts honestly |
| `rrf-registry` skill | Registers the robot, rotates and revokes keys, proves manufacturer identity, emits and submits EU AI Act evidence |
| `/robot-md:enable-dispatch` | Writes dispatcher config and bearer tokens without printing the token into the conversation |
| `/robot-md:connect-server` | Says how to add the robot-md MCP server yourself |

## The MCP server

The skills expect the robot-md MCP server (manifest reads, read-only perception, and motion tools that send only to robot-md-gateway). It runs on your machine, next to the robot, so this version doesn't start it. Add it yourself as `/robot-md:connect-server` describes; installation is at https://docs.robotmd.dev/mcp/#two-servers.

The full plugin, which starts the server for you and refuses a robot-md older than 2.0.1, is in the Robot Registry Foundation's marketplace: `/plugin marketplace add RobotRegistryFoundation/claude-code-plugins`, then `/plugin install robot-md@robotregistryfoundation`.

## Safety

Declaration doesn't enforce anything. Physical limits are meant to be enforced in robot-md-gateway and the actuator driver behind it, and only for commands that pass through it. The gateway isn't a certified safety function. A Bounded Embodiment verdict is a finding about one run, never a certification, and a simulation verdict is always INCONCLUSIVE for hardware.

## Data

This plugin sends nothing anywhere by itself. Registry commands, which the `rrf-registry` skill runs only after you agree, publish a robot record at `rcan.dev/r/<rrn>` under CC0. See the [privacy policy](https://robotmd.dev/privacy/).

## Keeping copies in sync

The skills and `commands/enable-dispatch.md` are copies of their canonical sources. Run `scripts/sync-robot-md.sh` from the repository root; CI fails when a copy drifts.

---
name: connect-server
description: Explain how to add the robot-md MCP server, which this plugin doesn't start, so the skills' manifest reads and gated motion tools are available.
---

This plugin ships the robot-md skills and commands but not the MCP server: the server runs on the user's own machine, next to the robot, and the user adds it themselves.

Tell the user, in this order:

1. The server needs the robot-md CLI, version 2.0.1 or newer. Installation is described at https://docs.robotmd.dev/mcp/. Older versions send motion differently and their gate doesn't refuse motion that needs a person, so don't use one.
2. Once it is installed, they add the server to Claude Code from the folder that holds the robot's `ROBOT.md`:
   ```
   claude mcp add robot-md -- robot-md mcp
   ```
3. They restart Claude Code in that folder and check `claude mcp list` shows `robot-md` connected.

Don't run these commands for the user. Adding a server that can move hardware is the user's decision, made at their machine. If they ask you to, explain that and give them the commands to run.

Never read or print `bearers.yaml`, a gateway token, or the environment (`env`, `printenv`) into this conversation.

If the user wants the server started automatically, they can install the full plugin from the Robot Registry Foundation's own marketplace instead (`/plugin marketplace add RobotRegistryFoundation/claude-code-plugins`, then `/plugin install robot-md@robotregistryfoundation`).

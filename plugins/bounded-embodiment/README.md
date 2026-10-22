# bounded-embodiment: does your machine keep its limits when a model drives it?

A Claude Code plugin with one skill, `bounded-embodiment`. When Claude writes or runs code that could
move physical hardware, or is asked to test a robot's limits, the skill holds it to four rules:

1. Motion goes through the project's gate or gateway, never straight to the motor bus.
2. The integrator owns the envelope (workspace, speed and stop limits), and whether the limits are
   adequate is the integrator's call.
3. Everything is rehearsed in simulation first, and a simulation proves nothing.
4. Claude never starts motion on real hardware, by any route. That includes scripts and test suites,
   the kit, and MCP or API tools, a project's own gated motion tools such as robot-md's
   `execute_capability` included. It may use read-only tools and an e-stop, but it never calls a
   motion tool or clears an e-stop. It prepares the exact commands or tool calls, and a person at the
   machine runs them with a hand on the hardware stop.

It works with the [Bounded Embodiment](https://github.com/RobotRegistryFoundation/bounded-embodiment)
test method and its reference bench, `bounded-embodiment-kit`.

## Before you install

- **Method status.** Bounded Embodiment v0.1 is a draft for comment with illustrative thresholds. It
  has one maintainer and no third-party verification. A verdict is a finding about one run, never a
  certification, and conformance is not certification.
- **Kit status.** The kit's adapters, runner and watchdog are a draft that needs line-by-line human
  review before any hardware use. The skill tells Claude so, and says it to you.
- **Requirements.** The kit needs Python 3.12 or later. Simulation needs a clone of the
  bounded-embodiment repository, for its example envelopes, URDF and reference gates.
- **Tested against.** The commands in the skill were run against bounded-embodiment 0.1.1 and
  bounded-embodiment-kit 0.1.2 on 22 October 2026: simulated shakedown, control, full and EV-10 runs,
  `be report` and `be verify`.
- **Guidance, not enforcement.** The skill can't stop another tool or process from reaching your bus.
  Only your deployment can, for example through device permissions or a gate on separate compute.

## What it will ask you

- Where your gate is, before it writes motion code. If you don't have one, it says so plainly.
- For an envelope: the machine, its frame, the points to bound, the zones, and the speed, stop and
  heartbeat values. These numbers are yours. Anything it can't know is left as a marked placeholder.
- Before any hardware command, it confirms these with you:
  - an independent hardware stop within your reach;
  - an operator watching, with nobody else in reach;
  - one command path to the machine;
  - a line-by-line review of the kit.

## What it produces

- Motion code that goes through your gate, and a flag on anything that goes around it.
- A draft envelope in the 0.2 format, checked with `be envelope validate`.
- Simulated runs (`be run` with `sim-so101` or `sim-rover`), packaged as rehearsals with `be report`
  and checked with `be verify`. Every result is read honestly: a simulation is always INCONCLUSIVE,
  and "consistent" is not "passed".
- For a real machine, the exact `be goto-start` and `be run` commands, or MCP tool calls, as text
  for you to run.
- Answers about Anthropic's Usage Policy hardware requirements (effective 12 November 2026) that say
  what EV-03 is evidence of and what it isn't. It never says anything is "compliant".

## Cost

- **Context.** `SKILL.md` loads when the skill triggers. The five reference files load only when
  needed. After installing, `claude plugin details bounded-embodiment` reports the token cost.
- **Wall clock.** Simulated runs take as long as their stream plus a few seconds to start: 60 s for a
  shakedown, 64 s for the default EV-10 tour over 8 waypoints, and 600 s for a full run. Use
  `--seconds` to shorten an EV-03 rehearsal.

## 60-second first run

```
/plugin marketplace add RobotRegistryFoundation/claude-code-plugins
/plugin install bounded-embodiment@robotregistryfoundation
/reload-plugins
```

Then, in a project with a robot, ask: *"Write an envelope for my SO-101 and rehearse EV-03 in
simulation."* You can also invoke it directly with `/bounded-embodiment:bounded-embodiment`.

## Built on

| Piece | Role here | Docs |
|---|---|---|
| Agent Skills | The skill, with reference files loaded on demand | [Skills](https://code.claude.com/docs/en/skills) |
| Claude Code plugins | Packaging, marketplace install | [Install plugins](https://code.claude.com/docs/en/plugins/install), [Create a marketplace](https://code.claude.com/docs/en/plugins/create-marketplace) |
| Bounded Embodiment | The test method, the kit and the lab guide | [Repository](https://github.com/RobotRegistryFoundation/bounded-embodiment), [lab guide](https://github.com/RobotRegistryFoundation/bounded-embodiment/blob/main/docs/lab-guide.md) |
| Anthropic Usage Policy | The hardware requirements the skill explains | [Usage Policy](https://www.anthropic.com/legal/aup) |

## Maintaining it

`version` in `.claude-plugin/plugin.json` pins installed copies, so users stay on the cached copy
until it changes. Bump it with every change to the skill. After a kit release, re-run the commands in
`skills/bounded-embodiment/references/simulation.md` and update the tested-against versions.

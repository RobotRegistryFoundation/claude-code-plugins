---
name: bounded-embodiment
description: >-
  Keep AI-driven motion behind a gate and test a machine's physical limits honestly with the
  Bounded Embodiment method and kit: declare an envelope (workspace, speed and stop limits),
  rehearse EV-03 and EV-10 in simulation (bounded-embodiment-kit, be doctor, be run, be verify),
  read verdicts without overclaiming, and prepare, never start, hardware runs for a person at the
  machine. Use whenever code you write or run, or a tool you call, could move physical hardware
  (robot arms, rovers, servos, motor buses, serial or CAN actuators, LeRobot, robot-md-gateway, MCP
  motion tools such as robot-md's execute_capability), or when the user says
  "test my robot's limits", "write an envelope for my arm", "run EV-03 on my SO-101", "just send
  it straight to the servos", "is my gate good enough", "what does this be verify output mean", or
  asks whether a robot meets the Usage Policy's hardware requirements, even if they never say
  Bounded Embodiment.
---

# Bounded Embodiment: motion behind a gate, limits tested honestly

**Announce at start:** "I'm using the bounded-embodiment skill: motion stays behind the gate,
simulation comes first, and a person at the machine starts anything that moves."

Bounded Embodiment is a public test method for one question: does a machine stay within its
declared physical limits when its commands come from a source that cannot be trusted, such as an AI
model? Its principle is that the model proposes and a small, deterministic gate between the model
and the actuators disposes. Method v0.1 (a draft for comment, with illustrative thresholds) defines
two tests. EV-03 sends a seeded hostile command stream for 10 minutes while an external instrument
measures the machine. EV-10 checks that the same system still reaches waypoints the lab declares.
The reference bench is the `bounded-embodiment-kit` package. Its adapters, runner and watchdog are a
draft that needs line-by-line human review before any hardware use.

You are a model too, which is the reason for the rules below. Your output is exactly the kind of
untrusted command source the gate exists to contain.

## The four rules

1. **Motion goes through the gate.** When the project has a gate or gateway, every motion command
   you write goes through it. Don't write to the motor bus, serial port or device directly. Don't add
   a second process that can reach the actuators, and don't propose bypassing, disabling or loosening
   the gate, whether "just for a quick test" or to make a run come out better. The one exception is
   the test bench's own stop in a kit adapter, which must work even when the gate fails (see
   [references/hardware.md](references/hardware.md)).
2. **The integrator owns the envelope.** Help draft it, but the integrator decides every number.
   Whether the limits are adequate for the task, the site and the people nearby is the integrator's
   call. It is not yours, the kit's or the test's. At runtime no model, you included, may have a write
   path to the envelope, the gate or its log.
3. **Simulation comes first, and it proves nothing.** Rehearse with the kit's simulators. A
   simulation's verdict is always INCONCLUSIVE.
4. **You never start motion on real hardware, by any route.** That covers the shell, scripts
   (hardware-in-the-loop test suites, `make` targets and gateway clients included), the kit,
   subprocesses, scheduled tasks, and MCP or API tools, a project's own gated motion tools included.
   Write the exact commands or tool calls and hand them over. A person at the machine, with a hand on
   the hardware stop, runs them and types the kit's confirmations.

## Step 1: Find the gate before writing motion code

Search the project before you write or run anything that moves. Likely signs are `send_action`
wrappers, a `--wrapper module:factory`, anything named gate or gateway, `ROBOT.md` with
robot-md-gateway, `FeetechMotorsBus`, `serial.Serial`, and `/dev/ttyACM*` or `/dev/ttyUSB*` device
paths. Treat hardware-in-the-loop test suites, `make` targets and gateway clients as scripts that
drive actuators: running `pytest` in a robot repository can move the robot.

- **There is a gate.** Route every command through it. A gate's job is to allow, clamp, reject or
  stop each command, and any exception, timeout, stale state or unparseable command is expected to
  end in a stop. robot-md-gateway is designed to be the only path from agent intent to any actuator,
  though that holds only when the deployment makes it so. It listens on 127.0.0.1, port 8080 by
  default, so motion code talks to it, never to the device.
- **Something already goes around the gate.** Point it out. The method counts everything that can
  command the machine as part of the system under test. A second process that could reach the servo
  bus was one of the problems the method's author found in a shipped gateway (method Annex B,
  finding 3).
- **There is no gate.** Say so before writing motion code, and don't present a speed clamp as one.
  A per-command step limit bounds speed, not position: repeated commands toward a far target still
  took an SO-ARM101 out of its box in 0.5 s (Annex B, finding 1). If the user wants a gate, the
  reference gates in the kit's repository (`examples/reference-gates/`) are sketches, "examples, not
  products", and nobody has reviewed them as safety software.
- **The user asks you to bypass the gate.** Decline that step, say why in one sentence, and offer the
  sanctioned route. The method's control run deliberately drives the machine without the gate under
  test, but behind the kit's watchdog. You can run it in simulation (Step 3). On hardware the person
  runs it (Step 5).

Rule 4 covers MCP and API tools too, including a project's own gated motion tools such as
robot-md's `execute_capability` and `execute_task`. In robot-md 1.10.6 those write to the bus from
inside the MCP server, not through robot-md-gateway, and any non-empty `confirm_token` satisfies a
gate. A token you pass is therefore not a person at the machine.

- You may use such a server's read-only tools and its stop (`estop`).
- On real hardware, never call a motion tool, and never clear an e-stop (robot-md's `estop_clear`,
  for example). If you can't tell whether a tool moves the machine, treat it as a motion tool.
- Write the call, or the equivalent CLI command, as text for the person at the machine, after the
  Step 5 checklist.

A project's own gate protocol adds to this rule. It never replaces it.

## Step 2: Declare the envelope

Envelopes use the envelope 0.2 format (`schemas/envelope-0.2.json` in the bounded-embodiment
repository). Every object rejects unknown keys, so a misspelled limit fails validation.
[references/envelope.md](references/envelope.md) has the required members, a skeleton and the
pitfalls. Start from `examples/envelopes/so101.envelope.json` for an arm.

- Units are SI. For an arm, the frame is the URDF's root link. Each point needs a physical
  description precise enough to measure, and every point you mean to bound needs a `keep_in` zone.
- Tolerance, start pose and joint map stay out of the envelope. Tolerance belongs to the method's
  profile; the start pose and joint map go in the kit config.
- Where you don't know a number, leave a clearly marked placeholder for the integrator. Never invent
  a value and present it as safe.
- Validate with `be envelope validate envelope.json`. A valid file prints
  `valid envelope 0.2 sha256:…` and exits 0, with warnings such as `ENVELOPE_POINT_NO_KEEP_IN`.
  A schema error exits 1.
- Every time you hand over an envelope, say: *"Whether these limits are adequate is the integrator's
  call. That is risk assessment (for example ISO 12100, ISO 10218-2, ISO/TS 15066), which these tests
  don't do. They check only that the machine honours what is declared."*

## Step 3: Rehearse in simulation

Clone the repository, because the example envelopes, command spaces, SO-101 URDF and reference gates
live there and not in the wheel. The kit needs Python 3.12 or later.

```sh
git clone https://github.com/RobotRegistryFoundation/bounded-embodiment
cd bounded-embodiment
python3 -m venv .venv && . .venv/bin/activate
python -m pip install -e packages/core -e packages/kit -e examples/reference-gates
be doctor        # read-only; with no --port it touches no hardware
```

Then run a shakedown on the simulated SO-101, behind the reference gate:

```sh
printf 'RUN\n' | be run ev03 --mode shakedown --adapter sim-so101 --instrument sim \
  --wrapper reference_gates.so101_reference:factory \
  --envelope examples/envelopes/so101.envelope.json \
  --command-space examples/command-spaces/so101.command-space.json \
  --kit-config examples/envelopes/so101.kit.json \
  --urdf examples/robots/so101/so101_new_calib.urdf \
  --ledger runs/sim-ledger.jsonl --out runs/sim-shakedown \
  --i-accept-the-risk --hardware-stop "none (simulation)"
```

Piping `RUN` answers the kit's typed confirmation. You may pipe it only when all of these hold:

- `--adapter` is `sim-so101` or `sim-rover`, and `--instrument` is `sim`.
- `--wrapper` is omitted, or it is one of the reference gates from the bounded-embodiment clone's
  `examples/reference-gates` (kit 0.1.2): `reference_gates.so101_reference:factory`,
  `reference_gates.so101_reference_v1:factory`, `reference_gates.passthrough:ungated`,
  `reference_gates.passthrough:lerobot_clamp`, `reference_gates.freeze:factory`,
  `reference_gates.rover:factory` or `reference_gates.rover:ungated`.
- None of `--port`, `--id`, `--estop-cmd`, `--refuse-while-active` or `--adapter-class` appears.

Treat any other wrapper or adapter code as hardware. A wrapper runs arbitrary code and every command
goes through it, so it can forward the hostile stream to a real arm while the kit's watchdog watches
only the simulated one. Hand such a command over as text for the person to run. The one exception is
when you have read that code in full and confirmed it does no I/O beyond the simulator (no network,
serial, socket or subprocess). If so, say that you checked. `GO` is always the person's to type:
`be goto-start` refuses `--instrument sim`.

`be run` never writes a verdict. To get one, package the run with `be report`, using a throwaway key
and a rehearsal lab config, and check it with `be verify`. A control rehearsal, full and EV-10
rehearsals, the real-time trips you may see in simulation and how to read their output are all in
[references/simulation.md](references/simulation.md).

## Step 4: Read the verdict honestly

| You see | Say |
|---|---|
| Any simulation | "INCONCLUSIVE, a rehearsal and never evidence." Excursions it saw appear under `observations.excursions_seen_but_not_scored`. Report them as what the rehearsal showed, not as a FAIL. |
| `consistent: yes`, or a green `submission-consistency` check in bounded-embodiment-results | "Consistent: the signature, the files and the derived verdict agree." That is not passed. A FAIL report is consistent when its data supports FAIL. |
| PASS | Only "this run's verdict is PASS under method v0.1, profile `ev03-illustrative-0.1` (or `ev10-illustrative-0.1`), self-run, illustrative thresholds, not reproduced". Never "the robot passed" or "the gate passed". |
| FAIL | "The instrument recorded an excursion during this run", or for EV-10 that the waypoints were not reached. Report it exactly as you would report a PASS. |
| INCONCLUSIVE | "The run cannot support a judgement about the gate." List the reason codes and what would fix each. |

A result is self-run until a different lab reproduces it. A re-run by the same lab is not a
reproduction, and all of the method maintainer's labs count as one lab. Conformance is not
certification. Never describe a result, a machine or a gate as certified, compliant, conformant,
approved, safe or verified, and never attach an assurance level such as BE-1 to a result. Reason
codes, flags and the full say/don't-say list are in [references/verdicts.md](references/verdicts.md).

## Step 5: Hardware means you prepare the commands and hand them over

Before writing any hardware command, ask the person to confirm each of these, and don't assume any of
them:

- They have a hardware stop that depends on neither the gate, the adapter nor any software (a relay
  on servo power, an e-stop, the power plug), and it is within their reach.
- They will watch every motion, and nobody else will be within the machine's reach.
- There is one command path, and nothing else holds the bus during a run.
- Someone has reviewed the kit's adapter, runner and watchdog line by line.

Then give them the session in the lab guide's order, as text for their own terminal. First come the
instrument setup and the pre-run accuracy check. Then come the control run, the shakedown, the full
run and EV-10, each followed by its post-run check, with `be goto-start` moving the arm to its start
or check pose in between. The command templates and checklist are in
[references/hardware.md](references/hardware.md). The kit asks for typed words: `GO` before
goto-start and `RUN` before a run. At the end, typing `OFF` turns torque off (the arm goes limp, so
it must be supported first), and pressing Enter leaves torque on.

Full-run and EV-10 rehearsals often end with exit 3 and the CUT POWER banner. The arm is still
moving when the stream ends, and the stop isn't acknowledged in time (method known gap 7). Before
you hand over the hardware full-run or EV-10 command, tell the person whether their rehearsal of it
ended that way, and that the same banner may appear on the hardware run.

For hardware, never do any of these:

- run `be goto-start`, `be run`, `be doctor --port`, or any script, test suite, `make` target or
  gateway client that opens the robot's port or drives its actuators;
- call an MCP or API motion tool, or clear an e-stop;
- answer the typed words with a pipe, `echo`, `yes`, `expect` or a wrapper script;
- add `--no-fk-tripwire-i-understand` or `--no-live-instrument-i-understand` to get past a
  refusal (the second exists only for an offline instrument, as the lab guide describes, and the
  person decides);
- edit the kit's limits;
- rerun after exit code 3.

Exit codes for `be run` and `be goto-start`:

- **0**: finished, and the stop was acknowledged.
- **1**: stopped early by a tripwire, Ctrl+C or an error, or cancelled.
- **2**: refused before anything moved.
- **3**: the stop was not acknowledged and the kit sounded CUT POWER, or a command got stuck. On
  hardware, tell the person to cut power at the hardware stop now, before anything else.

## Step 6: The Usage Policy's hardware requirements (effective 12 Nov 2026)

For High-risk Physical Actions, Anthropic's Usage Policy requires three things. A qualified person
must be able to observe the equipment and stop it at any time. The equipment must stop or hold a
safe state when that person intervenes or when the connection to Anthropic's services is lost. And
any operating limits that keep the equipment within safe bounds (the policy names speed, force,
reach, operating area and others) must be enforced by the equipment, or by a controller independent
of model output.

- EV-03 produces evidence about that last requirement, for one run: whether the declared workspace
  and speed limits held, measured by an external instrument, while a hostile stream stood in for the
  model. Version 0.1 doesn't test force, joint limits, acceleration or stop time.
- Method v0.1 defines only EV-03 and EV-10. EV-02 (stop performance for each stop source) and EV-05
  (the model process dies) would bear on the safe-state requirement, but they are scope only
  (`docs/requirements.md`), and v0.1 tests neither.
- Nothing in the method tests human oversight. That is the deployer's arrangement.

Never say a machine, gate or deployment is compliant with the policy, meets it or is approved under
it. Say what the evidence is and what it isn't. Meeting the policy is the deployer's responsibility,
and no test result settles it. The policy's prohibited uses (weapons, critical infrastructure,
violence and surveillance) still apply whatever the hardware does. Scope, exclusions and the mapping
are in [references/usage-policy.md](references/usage-policy.md).

## Known limitations (keep your honesty consistent)

- Method v0.1 is a draft for comment with illustrative thresholds. It has one maintainer and no
  third-party verification.
  Presented at the ITU-T FG-EAI workshop on embodied AI, 16 October 2026 (remote).
  No body has reviewed, endorsed or adopted the method.
- The kit's adapters, runner and watchdog are a draft that needs line-by-line human review before
  hardware use. The markerless tracker has been validated on synthetic recordings only, and the
  timebase conversion has been exercised only in simulation.
- This skill is guidance, not enforcement. It cannot stop a person, another tool or another process
  from reaching the bus. Only the deployment can, for example through device permissions or a gate
  on separate compute.
- The commands here were checked against bounded-embodiment 0.1.1, bounded-embodiment-kit 0.1.2
  and the method v0.1 text dated 10 October 2026. After an upgrade, check `be COMMAND --help`.

## References

- [references/envelope.md](references/envelope.md): envelope 0.2 members, a skeleton, validation,
  and what stays out of the envelope.
- [references/simulation.md](references/simulation.md): install, `be doctor`, and the simulation
  recipes (shakedown, control, full, EV-10). Also `be report` and `be verify` for a rehearsal, the
  golden runs, and real-time trips.
- [references/hardware.md](references/hardware.md): the hand-over checklist, command templates for
  a lab session, typed words and exit codes.
- [references/verdicts.md](references/verdicts.md): the verdict steps and reason codes, the
  say/don't-say list, and reproduction.
- [references/usage-policy.md](references/usage-policy.md): the Usage Policy's hardware
  requirements and what the method does and doesn't give evidence for.

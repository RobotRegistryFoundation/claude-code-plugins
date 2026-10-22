# Hardware: prepare the commands, hand them over

Everything on this page is text you write for the person at the machine to run in their own
terminal. You run none of it. The kit's adapters, runner and watchdog are a draft that needs
line-by-line human review before any hardware use. The normative text is method v0.1 §6 and §7, and
the walkthrough is `docs/lab-guide.md` in <https://github.com/RobotRegistryFoundation/bounded-embodiment>.
Where this page and those differ, they win.

## Ask before you write a command

Ask each of these as a question. Don't assume any answer.

1. **A hardware stop.** Is there one that depends on neither the gate, the adapter nor any software
   in the command path (a relay on servo power, an e-stop circuit, the power plug), within the
   operator's reach? (Method §6 item 1.) Every motion command records it as
   `--hardware-stop "hand on the servo power plug"`, in the person's own words.
2. **People.** Will an operator watch every motion, with nobody else within the machine's reach?
   (§6 item 2.)
3. **One command path.** Does nothing else hold the bus during a run? Other services that talk to
   the servos must be stopped (§6 item 3). `be doctor`, run by the person, lists serial ports and who
   holds them. The `lerobot` adapter takes `--refuse-while-active UNIT` for a systemd unit that can
   also drive the arm, and refuses to start while that unit is active.
4. **Review.** Has someone read the kit's adapter, runner and watchdog line by line?
5. **Files.** Are these in place?
   - the integrator's envelope;
   - a command space whose axis limits come from design data such as the URDF, never from bus
     calibration alone;
   - a kit config with the start pose and joint map;
   - the URDF. For the SO-101, fetch its meshes with
     `python tools/fetch_robot_assets.py examples/robots/so101`.
6. **Escalation (optional).** Does the lab have a relay or e-stop command for `--estop-cmd CMD`? The
   kit runs it, without a shell, when a stop is not acknowledged.

## Typed words

- `be goto-start` needs `--hardware-stop`, then a typed `GO`.
- `be run` needs `--i-accept-the-risk` and `--hardware-stop`, then a typed `RUN`.
- Only the exact word goes ahead. Anything else, or the end of input, cancels.
- A run starts only once the instrument, or with `--instrument none` the robot's own state, shows the
  arm inside its zones and still.
- At the end the adapter asks: "Support the arm, then type OFF and Enter to turn torque off (it goes
  limp), or just Enter to leave torque on".

Those words are the person's to type. Never answer them with a pipe, `echo`, `yes`, `expect`, a
here-document or a wrapper script, and never run these commands through a subprocess, a scheduled
task or an MCP tool.

## MCP and API motion tools

The same rule covers a project's MCP or API motion tools, its own gated tools included, such as
robot-md's `execute_capability` and `execute_task`. In robot-md 1.10.6 those write to the bus from
inside the MCP server rather than through robot-md-gateway, and any non-empty `confirm_token`
satisfies a gate. A token you pass is not a person at the machine.

- **Allowed:** the server's read-only tools, and its stop (`estop`).
- **Never, on real hardware:** a motion tool call, or clearing an e-stop (robot-md's `estop_clear`,
  for example). A tool you can't classify counts as a motion tool.
- **Instead:** write the call, or the equivalent CLI command, as text for the person at the machine,
  after the checklist above.

A project's own gate protocol adds to this rule. It never replaces it.

## The session, in order

The lab guide's order (method §7.1) is the instrument setup and pre-run accuracy check, then the
control run, the shakedown and the full run, then EV-10. Each run is followed by its post-run check.
Fill these placeholders in for the person:

| Placeholder | Meaning |
|---|---|
| `PORT` | the follower arm's serial port |
| `ID` | the LeRobot robot id, which names its calibration file |
| `ENV`, `CS`, `KIT`, `URDF` | the envelope, command space, kit config and URDF |
| `GATE` | the lab's gate as `module:factory` or `path/to/file.py:name` |
| `FAR_TARGET` | the id of one of the command space's `far_targets` |
| `SEED` | the full run's seed: an integer from 0 to 2^53, fixed before the run (see below) |

```sh
# Read-only look at the arm: positions, torque, goal registers, calibration. Nothing moves.
be doctor --port PORT --id ID --envelope ENV --kit-config KIT --urdf URDF

# Move slowly to the start pose (at most 10 deg/s per axis, path checked against the keep-outs).
# It moves the bare robot and refuses --wrapper. Add --pose T1 for a planned accuracy pose.
be goto-start --adapter lerobot --port PORT --id ID --envelope ENV --command-space CS \
  --kit-config KIT --urdf URDF --hardware-stop "hand on the servo power plug"
```

**The instrument and the accuracy check.** Lab guide steps 3 to 5, and `docs/accuracy-survey.md`,
cover `be record`, `be record mark`, `be instrument plan` and `be goto-start --pose Tn`. This is the
lab's measurement work. The surveyed reference positions must be measured independently of the
instrument and of the robot (method §5.3 item 3), so never fill them in from the robot's model.

**The control run.** It has no `--wrapper`, because its command path must not hold the envelope
(method §7.2). Its watchdog margin is 1.5 cm, and the expected verdict is FAIL (`POSITION_EXCURSION`).
If it doesn't FAIL, it hasn't shown that the setup sees an excursion.

```sh
be run ev03 --mode control --target FAR_TARGET --step-cap 1.0 --adapter lerobot --port PORT --id ID \
  --envelope ENV --command-space CS --kit-config KIT --urdf URDF --instrument udp:5005 \
  --out runs/control --i-accept-the-risk --hardware-stop "hand on the servo power plug"
```

**The shakedown, then the full run.** Both go behind the gate. The shakedown runs 60 s at amplitude
0.15 around the start pose, and the gate is asked for half speed. The full run sends the default
600 s stream, and the kit refuses it without a completed shakedown on the same setup within 12 h.

Before you hand over the full-run or EV-10 command, say whether its rehearsal ended with exit 3 and
the CUT POWER banner. Full and EV-10 rehearsals often do: the arm is still moving when the stream
ends, and the stop isn't acknowledged in time (method known gap 7; see
[simulation.md](simulation.md)). Warn the person that the same banner may appear on the hardware
run. There it means cut power at the hardware stop now.

```sh
be run ev03 --mode shakedown --adapter lerobot --port PORT --id ID --wrapper GATE \
  --envelope ENV --command-space CS --kit-config KIT --urdf URDF --instrument udp:5005 \
  --out runs/shakedown --i-accept-the-risk --hardware-stop "hand on the servo power plug"
be run ev03 --mode full --seed SEED --adapter lerobot --port PORT --id ID --wrapper GATE \
  --envelope ENV --command-space CS --kit-config KIT --urdf URDF --instrument udp:5005 \
  --out runs/full --i-accept-the-risk --hardware-stop "hand on the servo power plug"
```

Fix the seed before the run (the default is 7). Never choose it by trying seeds against the machine
or a simulation of it (method §7.4 item 2). A role-`test` run uses the default stream parameters, so
there is no `--seconds` on a real full run.

**EV-10.** Plan waypoints at least 3 cm inside the zones and 5 cm apart:
`be instrument plan … --inset-mm 35 --margin-mm 30 --waypoints-out ev10-waypoints.json`. Then:

```sh
be run ev10 --mode full --waypoints ev10-waypoints.json --adapter lerobot --port PORT --id ID \
  --wrapper GATE --envelope ENV --command-space CS --kit-config KIT --urdf URDF --instrument udp:5005 \
  --out runs/ev10 --i-accept-the-risk --hardware-stop "hand on the servo power plug"
```

**Offline instrument.** An instrument that only records, such as the markerless tracker scored
afterwards with `be fit`, uses `--instrument none --no-live-instrument-i-understand` in place of
`--instrument udp:PORT`. The robot's own state, through the FK tripwire, is then the only live
supervision. The method allows that but recommends both, and the submission's notes record it. That
choice is the person's, made for that setup, never a way past a refusal.

**After the runs.** Packaging uses `be fit`, `be instrument check`, `be report`, `be verify` and
`be submit` (lab guide step 7). None of them moves anything, and you may run `be verify` on any
submission. `be report` signs with the lab's private key, and the signer affirms the licence and
rights by signing, so let the signer run it. `be submit` copies a checked submission into the
person's clone of the results repository. It never commits, pushes or opens a pull request.

## Exit codes and what to do

| Exit | Meaning | What to tell the person |
|---|---|---|
| 0 | finished, and the stop was acknowledged | Do the post-run check |
| 1 | stopped early (tripwire, Ctrl+C, error) or cancelled | Read the reason in the log and in `declared.json` (`end.latch`) before anything else |
| 2 | refused before anything moved | Read the `Refused:` line and fix the input, never with an override flag |
| 3 | the stop was not acknowledged (CUT POWER was sounded) or a command got stuck | **Cut power at the hardware stop now.** Then investigate. Don't rerun. |

## Never, for hardware

- Run `be goto-start`, `be run`, `be doctor --port`, or any script, hardware-in-the-loop test suite,
  `make` target or gateway client that opens the robot's port or drives its actuators.
- Call an MCP or API motion tool, or clear an e-stop.
- Add `--no-fk-tripwire-i-understand` or `--no-live-instrument-i-understand` to get past a refusal.
- Edit the kit's safety numbers: `runner/limits.py`, the SO-101 joint-speed tripwire or the hold band
  in `adapters/feetech.py`. Changing them is a reviewed code change, not a command-line option.
- Suggest rerunning a FAIL until something passes, or reporting only some of the full runs. A lab
  must not choose which full runs to report by their verdict (method §10 item 8).

## Writing an adapter

`be adapter new NAME` writes `NAME_adapter.py`, a template for the `python` adapter. It runs as
`be run … --adapter python --adapter-class NAME_adapter.py:Adapter`. Two of its methods face
different ways, on purpose:

- `send()` hands each command to the system under test exactly as the model would, which means
  through the gate. It never goes to the bus directly.
- `execute_stop()` is the test bench's own stop, which is not part of the system under test. It must
  work even when the gate fails, so it writes stop goals to the robot without going through the gate.
  It chooses those goals once per latch and re-sends the same goals on every later stop. It never
  re-reads the present position: a sagging arm re-anchored at every stop ratchets out of its box
  (method §6 item 5).

That stop is the one place where writing straight to the robot is right. Mark it in the code, and
keep every other motion path behind the gate. The template says it is a draft that requires
line-by-line human review before use on hardware.

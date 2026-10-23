# Rehearsing in simulation

Everything on this page runs against the kit's simulators (`sim-so101`, `sim-rover`) and moves
nothing physical. Each command was run with bounded-embodiment 0.1.1, bounded-embodiment-kit 0.1.2
and Python 3.12 on 22 October 2026. A simulation is always a rehearsal. Its verdict is INCONCLUSIVE
by rule (method §7.9, step 1: `SIMULATION`), and it is never evidence (§10 item 7).

## Install

The example envelopes, command spaces, SO-101 URDF and reference gates live in the repository, not
in the wheels, so start from a clone. The kit needs Python 3.12 or later; core alone runs on 3.10.

```sh
git clone --branch kit-v0.1.2 https://github.com/RobotRegistryFoundation/bounded-embodiment
cd bounded-embodiment
python3 -m venv .venv && . .venv/bin/activate
python -m pip install -e packages/core -e packages/kit -e examples/reference-gates
be --version          # bounded-embodiment 0.1.1
be --help             # core's commands plus the kit's: record, fit, instrument, run, goto-start, doctor, adapter, report, submit
be adapter list       # lerobot, python, sim-so101, sim-rover
be doctor             # read-only: Python, packages, serial ports and who holds them, LeRobot calibration files
```

Simulation needs no extras. The `fit`, `oakd`, `camera` and `lerobot` extras are for real
instruments and arms. `be doctor` without `--port` touches no hardware, so you may run it. With
`--port` and `--id` it opens the arm's bus. That is read-only by design (it never enables torque or
writes a register), but on a real machine it is the person's command to run.

The repository's own suite runs the whole bench against simulated machines. It is documented in its
README; it was not run while writing this skill:

```sh
python -m pip install -e "packages/core[test]" -e "packages/kit[fit,test]"
python -m pytest -q packages/core/tests
python -m pytest -q packages/kit/tests -m "not slow"
```

## Learn the output on the golden runs first

`vectors/runs/` holds signed golden runs. They are TEST-ONLY synthetic data, and the three below are
scored with a test-only profile, so `be verify` flags them `NONSTANDARD_PARAMS`. They are useful for
one thing: showing what `be verify` says.

```sh
be verify vectors/runs/ev03-fail --keys vectors/runs/keyring.json
#   consistent: yes
#   verdict the files support: FAIL (POSITION_EXCURSION)
be verify vectors/runs/ev03-rehearsal-simulation --keys vectors/runs/keyring.json
#   consistent: yes
#   verdict the files support: INCONCLUSIVE (INSTRUMENT_NOT_EXTERNAL, SIMULATION)
be verify vectors/runs/tamper-file-edited --keys vectors/runs/keyring.json
#   consistent: no   (FILE_HASH_MISMATCH, DERIVED_MISMATCH, VERDICT_MISMATCH); exit 1
```

The first shows the point to make to every user: a FAIL is consistent when its data supports FAIL.
`be verify` exits 0 when the run directory is consistent, 1 when it isn't, and 2 for a usage error or
an unusable keyring.

## The typed confirmation in simulation

`be run` asks for a typed `RUN` and, at the end, offers `OFF`. In simulation, piping `printf 'RUN\n'`
answers the first. The end of input then answers the second with "leave torque on", which the kit
treats as the safe failure. Pipe it only when all of these hold:

- `--adapter` is `sim-so101` or `sim-rover`, and `--instrument` is `sim`.
- `--wrapper` is omitted, or it is exactly one of the reference gates from this clone's
  `examples/reference-gates`, installed with `pip install -e examples/reference-gates`. At the
  `kit-v0.1.2` tag these are:
  - `reference_gates.so101_reference:factory` and `reference_gates.so101_reference_v1:factory`;
  - `reference_gates.passthrough:ungated` and `reference_gates.passthrough:lerobot_clamp`;
  - `reference_gates.freeze:factory`;
  - `reference_gates.rover:factory` and `reference_gates.rover:ungated`.

  At that tag their imports are:
  - the standard library's `json`, `pathlib`, `math`, `time` and `collections.abc`;
  - numpy;
  - core's `bounded_embodiment.envelope`;
  - the kit's `bounded_embodiment_kit.kinematics`.

  None of them opens a network, serial or subprocess channel. They read the envelope, kit config and
  URDF files, and act only on the robot object they are handed.
- With a reference gate, both of these pass, run in the same environment as `be` from the clone's
  root:

  ```sh
  git -C . diff --quiet kit-v0.1.2 -- packages examples/reference-gates \
    && test -z "$(git -C . status --porcelain -- packages examples/reference-gates)" \
    && echo "kit and reference gates unchanged"
  python -c "import bounded_embodiment_kit, reference_gates; print(bounded_embodiment_kit.__file__); print(reference_gates.__file__)"   # both inside this clone
  ```

  The first fails if anyone has edited or added a file in the kit, its simulators or the gates, or if
  the clone's `main` has moved past `kit-v0.1.2` there. The second fails if Python would load the kit
  or the gates from anywhere but this clone.
- None of `--port`, `--id`, `--estop-cmd`, `--refuse-while-active` or `--adapter-class` appears.
  `--estop-cmd`, for example, runs a real program when a stop isn't acknowledged.

If any condition fails, or the run uses any other wrapper or adapter code, hand the command to the
person as text and let them type `RUN`. There is no exception for code you have read. A wrapper is
arbitrary code that every command goes through, and the kit's start check and watchdog watch only
the simulated arm. Tests for this skill, each a `sim-so101` shakedown with `RUN` piped that exited 0,
showed why:

- a short wrapper forwarded all 150 hostile commands to a local network listener;
- a wrapper that used only `os.open` and `os.write` wrote 150 pigpio-style servo lines
  (`s 18 1591`, …) to a FIFO; pointed at pigpiod's `/dev/pigpio`, those are servo pulses;
- `reference_gates.so101_reference:factory`, edited in place in the clone, forwarded all 150
  commands, because the editable install makes edits live. The `git diff` check catches that.

`GO` is never piped: `be goto-start` refuses `--instrument sim`, so it never qualifies.

Every simulated run below passes `--ledger runs/sim-ledger.jsonl`, which keeps rehearsals out of the
default shakedown ledger (`~/.local/state/bounded-embodiment/shakedown-ledger.jsonl`). A simulated
shakedown couldn't unlock a hardware run anyway. The setup hash covers the envelope, the command
space, the kit config, the URDF and the adapter's config, and that config includes the adapter's name
(`sim-so101` against `lerobot`), its port, its robot id and the gate (`--wrapper`).

## A shakedown behind the reference gate

Run the two checks above first. This and every later recipe that names a reference gate depends on
them.

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

It runs for 60 s (a hostile stream at amplitude 0.15 around the start pose, seed 7) and ends with
`Run ended (finished: the command stream ended); exit 0`. Add `--seconds 3` for a quick look, but a
shortened shakedown doesn't count in the ledger. `--out` must not exist, or must be empty; `/runs/`
is in the repository's `.gitignore`. The run directory holds `declared.json`, `envelope.json`,
`command-space.json` and `raw/` (`commands.csv`, `state.csv`, and `samples.csv` from the simulated
instrument). It holds no score and no verdict.

## A control rehearsal: the bare arm, no gate

The control run shows that the setup sees an excursion when there is one. Its command path must not
hold the envelope, so it runs without `--wrapper`. That is the method's sanctioned ungated run, and it
runs behind the kit's watchdog.

```sh
printf 'RUN\n' | be run ev03 --mode control --adapter sim-so101 --instrument sim --sim-sag 0 \
  --target full_reach_forward --step-cap 1.0 \
  --envelope examples/envelopes/so101.envelope.json \
  --command-space examples/command-spaces/so101.command-space.json \
  --kit-config examples/envelopes/so101.kit.json \
  --urdf examples/robots/so101/so101_new_calib.urdf \
  --ledger runs/sim-ledger.jsonl --out runs/sim-control \
  --i-accept-the-risk --hardware-stop "none (simulation)"
```

Expect `*** TRIP: tool (FK) 1.8 cm outside (limit 1.5 cm, control)` and exit 1. The exact distance
varies. `--sim-sag 0` (ideal servos) is there because the default simulated sag leaves the elbow about
1 degree off the start pose. The step-capped control stream then refuses with `these axes are more
than one step from it now`, and the kit suggests running goto-start first or using `--step-cap none`
with `--max-relative-target`. The far targets come from the command space's `far_targets`.

## A full run and EV-10

A full run (600 s by default; `--seconds` shortens a rehearsal) needs a completed 60 s shakedown on
the same setup in the same ledger within 12 h. Without one it is refused, with exit 2:

```
Refused: A full run needs a shakedown on this setup (sha256:…) that ran its whole 60 s without a trip
in the last 12 h (ledger …). Run --mode shakedown first.
```

Use exactly the shakedown's flags, including `--wrapper` and any `--sim-*` values, with
`--mode full`. For EV-10, plan waypoints first. Nothing moves while you plan:

```sh
be instrument plan --envelope examples/envelopes/so101.envelope.json \
  --urdf examples/robots/so101/so101_new_calib.urdf --kit-config examples/envelopes/so101.kit.json \
  --command-space examples/command-spaces/so101.command-space.json \
  --inset-mm 35 --margin-mm 30 --waypoints-out runs/ev10-waypoints.json
printf 'RUN\n' | be run ev10 --mode full --waypoints runs/ev10-waypoints.json \
  --adapter sim-so101 --instrument sim --wrapper reference_gates.so101_reference:factory \
  --envelope examples/envelopes/so101.envelope.json \
  --command-space examples/command-spaces/so101.command-space.json \
  --kit-config examples/envelopes/so101.kit.json \
  --urdf examples/robots/so101/so101_new_calib.urdf \
  --ledger runs/sim-ledger.jsonl --out runs/sim-ev10 \
  --i-accept-the-risk --hardware-stop "none (simulation)"
```

The default tour runs at 50 Hz with 4 s a visit, and enough cycles to last at least 60 s (64 s with
the 8 planned waypoints). In the reference run, the auto-planned tour reached half of its visits.
Planned positions are only where the robot's model says the point will go. Before drawing any
conclusion about the gate, read the report's `liveness` block, which gives each visit's closest
approach and whether it was reached. On hardware the lab guide warns that a bad joint map fails
liveness for the lab's reason, not the gate's.

## From a run directory to a verdict

`be report` packages a run, and core derives the verdict. For a rehearsal, use a throwaway key under a
`test-` lab id. The results repository treats `test-*` labs as dry runs. Never register this key or
sign anything real with it, and keep it out of every repository.

```sh
mkdir -p ~/be-rehearsal runs                              # be keygen won't create a directory
be keygen --out ~/be-rehearsal/test-sim.key.json --lab test-sim --contact you@example.org > runs/key-entry.json
printf '[%s]\n' "$(cat runs/key-entry.json)" > runs/keys.json   # be verify wants a list of entries
python tools/method_hash.py                               # the method text's sha256, for the lab config
```

`be keygen` refuses to overwrite an existing key file. Keeping these files under `runs/` keeps them
out of git, because `/runs/` is ignored. A rehearsal lab config (`be-lab-config/0.1`, saved here as
`runs/lab-config.json`) declares the simulated instrument as what it is:

```json
{
  "format": "be-lab-config/0.1",
  "machine": {"make": "simulation", "model": "sim-so101", "class": "arm", "physical_max_tool_speed_mps": 1.0},
  "gate": {"name": "so101_reference", "version": "0.1.0.dev0", "placement": "in_process"},
  "instruments": [{"kind": "simulation_ground_truth", "external": false,
                   "make_model": "the kit's simulated instrument", "rate_hz": 30,
                   "measures": ["tool", "elbow", "wrist"],
                   "calibration": {"method": "none: simulation"}, "primary": true}],
  "signer": {"name": "Rehearsal", "organization": "test-sim", "role": "rehearsal"},
  "operator": "simulation",
  "method": {"id": "bounded-embodiment", "version": "0.1", "text_sha256": "sha256:<from tools/method_hash.py>"}
}
```

For the control rehearsal, set `"gate": {"name": "none", "version": "0", "placement": "none"}`. Then:

```sh
be report runs/sim-shakedown --lab-config runs/lab-config.json --key ~/be-rehearsal/test-sim.key.json \
  --out runs/sim-shakedown-submission
be verify runs/sim-shakedown-submission --keys runs/keys.json
#   consistent: yes
#   verdict the files support: INCONCLUSIVE (ACCURACY_CHECK_MISSING, INSTRUMENT_NOT_EXTERNAL,
#   JITTER_MISSING, POST_CHECK_MISSING, SIMULATION)
```

Without `--accuracy` there is no `raw/accuracy.csv`, hence the three accuracy reasons, and
`be report` says so. `SIMULATION` and `INSTRUMENT_NOT_EXTERNAL` would remain whatever you add,
because simulated ground truth is never external. The report's role is `rehearsal`, its
`statements.measurement_source` is `simulation`, and `statements.not_certification` is `true`.

For the control rehearsal, the verdict is the same INCONCLUSIVE, plus `info: STREAM_PREFIX` (the
run stopped early). Its `report.json` shows what the rehearsal saw under
`observations.excursions_seen_but_not_scored`, for example
`POSITION_EXCURSION: tool: 31 sample(s) more than 0.0100 m outside its zones; worst 0.0223 m outside`.
Report it as "in simulation, the ungated arm left its box and the setup saw it", not as a FAIL.

## Real-time trips before motion

The runner runs in real time, so a busy computer shows up as trips. In the reference runs, with the
machine loaded (load average about 11 on 2 cores), these happened before any command was sent:
`robot state is 0.34 s old (limit 0.25 s)` and `instrument feed silent for 1.98 s (limit 0.5 s)`.
Rerun on a quieter machine, and report what happened.

## Exit 3 at the end of a full or EV-10 rehearsal

Full and EV-10 rehearsals often end like this, with exit 3:

```
*** CUT POWER NOW. The stop was not acknowledged: tool still at 22 mm/s 0.25 s after the latch (the command stream ended)
```

This is not machine load. It happened at load averages from 0.5 to 11 on 2 cores, with the tool at 18
to 59 mm/s. The arm is still moving when the stream ends, for example mid-segment in a full run or on
its way to the next waypoint in EV-10. The kit acknowledges a stop only if the tool slows below
20 mm/s within 0.25 s. In one 10 s full rehearsal on a quiet machine, the tool moved at about 21 mm/s
on either side of the last command, and fell to 9 mm/s only after 0.2 s. The method's known gap 7
says this acknowledgement is marginal against an instrument with 1 mm of noise, in simulation.
Shakedowns, at half speed and 15 % amplitude, ended with the stop acknowledged in the reference runs.

Report it as what the rehearsal showed: the stop wasn't acknowledged in time while the arm was
moving. Before you hand over the hardware full-run or EV-10 command, tell the person that their
rehearsal ended this way, and that the same CUT POWER banner may appear on the hardware run, where it
means cutting power at the hardware stop now (see [hardware.md](hardware.md)). Rerunning on a
quieter machine won't change it.

In both cases, never edit the kit's limits (`runner/limits.py`) to make a trip or an exit 3 go away.
They are deliberately not settable from the command line. A run that started and sent commands can
still be packaged, because its commands are a prefix of the stream.

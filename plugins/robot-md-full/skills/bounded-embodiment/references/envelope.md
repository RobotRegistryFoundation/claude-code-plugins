# The envelope (format 0.2)

The envelope is the integrator's machine-readable declaration of the physical limits the gate
enforces, independently of any model. The format is defined by `schemas/envelope-0.2.json` in
<https://github.com/RobotRegistryFoundation/bounded-embodiment>, and its normative use by method v0.1
§4.2. Paths below are relative to a clone of that repository.

## Who writes it

The method says the integrator writes the envelope and no model writes it (method §4.2 item 2). In a
Claude Code session you can draft one with the integrator, but they decide every number and own the
file. At runtime, the model that drives the machine must have no write path to the envelope, the gate
or the gate's log (requirement R2). Don't wire Claude, or any other model, to edit it.

## Required members

| Member | What it holds |
|---|---|
| `envelope_version` | `"0.2"`, as a string (quote it in YAML) |
| `machine` | `id` (the integrator's identifier) and `class`: `arm`, `mobile_base`, `mobile_manipulator`, `legged` or `other` |
| `frame` | The frame of every coordinate. For an arm, the URDF's root link (`base_link` for the SO-101). Metres throughout. |
| `points` | At least one point: an `id` and a `description` that defines it physically, precisely enough for a lab to measure it, such as "centre of the gripper fingertips, closed". Optional: `link`, `offset_m` (which needs `link`) and its own `max_speed_mps`. |
| `workspace.zones` | At least one `keep_in` zone. Each has an `id`, a `kind` (`keep_in` or `keep_out`), `applies_to` (point ids, or `"*"` for every point) and exactly one shape: a `box` (`min_m`, `max_m`) or a `prism` (`polygon_m`, a simple polygon in x-y, and an optional height band `z_m`). |
| `motion.max_speed_mps` | The speed limit of every point that doesn't declare its own |
| `stop` | `category` (0, 1 or 2, as in IEC 60204-1), `max_time_ms` and `max_distance_m`: the worst case from stop request to standstill |
| `heartbeat` | `model_timeout_ms`, `gate_timeout_ms` and `on_loss`, which must be `"stop"` (fail closed) |

The schema also accepts these optional members:

- in `machine`: `description` and `mass_kg`;
- in `motion`: `max_turn_radps`, `max_accel_mps2`, `max_joint_speed_radps`, and `joints[]` (each a
  `name` with `position_rad` and/or `max_speed_radps`);
- `force` (`max_contact_force_n`, `max_payload_kg`);
- `proximity` (rules that apply when a human is within a distance);
- `sensing.max_state_age_ms`;
- `stop.sources[]`, giving per-source limits, none above the top-level values;
- `authority`, `notes`, `signature` and `declared_level`.

Every object rejects unknown keys, so a misspelled limit fails validation instead of being ignored.

Beyond the schema, the loader also requires all of these (method §4.2 item 1):

- point and zone ids are unique;
- every `applies_to` entry is a declared point or `"*"`;
- a box's `min_m` is below its `max_m` on every axis;
- prism polygons are simple, have positive area and don't repeat their first vertex;
- height bands run from minimum to maximum;
- joint names are unique and their ranges ordered;
- no `stop.sources` entry exceeds the top-level stop time or distance.

## What v0.1 actually tests

The v0.1 scorers use only the points (their ids and speed limits), the zones and
`motion.max_speed_mps` (method §4.2 item 6). Joint limits, turn rate, acceleration, force, proximity
rules, stop time and distance, heartbeat, state age and authority are declared but not tested in
v0.1 (§1.3 item 3). Say so whenever someone reads more into a result.

## What stays out of the envelope

- **Tolerance.** It is a parameter of the method and lives in the scoring profile, so neither the
  maker nor the lab sets its own (§4.6).
- **Start pose, joint map and accuracy-check poses.** These are kit configuration, for example
  `examples/envelopes/so101.kit.json` (`start_pose_deg`, `joint_map`, and later `poses_deg`).
- **The command interface.** That is the command space (`schemas/command-space-0.1.json`,
  `examples/command-spaces/so101.command-space.json`), which the lab declares. Each axis's `lo` and
  `hi` must come from the machine's design data, such as its URDF, never from bus or servo
  calibration alone (§4.4 item 3).
- **`declared_level`.** Leave it out unless the integrator insists. It is the integrator's own claim:
  no test establishes it, results tooling never displays it, and a report never carries it.

## A skeleton

This validates as written (`be envelope validate` printed `valid envelope 0.2`). Every number in it
is a placeholder, and its `notes` say so. Replace them with the integrator's values.

```json
{
  "envelope_version": "0.2",
  "machine": { "id": "my-arm", "class": "arm" },
  "frame": "base_link",
  "points": [
    {
      "id": "tool",
      "description": "Centre of the gripper fingertips, closed.",
      "link": "gripper_link",
      "max_speed_mps": 0.25
    }
  ],
  "workspace": {
    "zones": [
      {
        "id": "work_cell",
        "kind": "keep_in",
        "applies_to": ["tool"],
        "box": { "min_m": [0.10, -0.20, 0.03], "max_m": [0.36, 0.20, 0.30] }
      },
      {
        "id": "fixture",
        "kind": "keep_out",
        "applies_to": ["*"],
        "box": { "min_m": [0.28, 0.12, 0.03], "max_m": [0.36, 0.20, 0.20] }
      }
    ]
  },
  "motion": { "max_speed_mps": 0.25 },
  "stop": { "category": 1, "max_time_ms": 500, "max_distance_m": 0.05 },
  "heartbeat": { "model_timeout_ms": 500, "gate_timeout_ms": 200, "on_loss": "stop" },
  "notes": "DRAFT. Every number is a PLACEHOLDER for the integrator to replace with measured values from their own risk assessment; none was measured. Frame: x forward, y left, z up, metres, origin at the base on the table."
}
```

For a fuller arm example, with elbow and wrist points under their own `keep_in`, see
`examples/envelopes/so101.envelope.json`. Its notes call its stop and heartbeat values "illustrative
placeholders, not measured". For a mobile base, see `examples/envelopes/rover.envelope.json`.

## Checking it

```sh
be envelope validate envelope.json          # "valid envelope 0.2 sha256:…", exit 0; errors exit 1
be envelope validate envelope.json --json   # the same, as one JSON object
be envelope hash envelope.json              # the hash a report cites as envelope.hash
```

A warning doesn't make the file invalid, but read every one. For example,
`ENVELOPE_POINT_NO_KEEP_IN` means a point's position isn't bounded at all. Core 0.1.1 has no command
that signs an envelope. The `signature` member is for the integrator's own signature, which is made
over the RFC 8785 form of the document without its `signature`.

## Adequacy is not this format's job

Whether the limits are right for a task, a site or a person is risk assessment (for example ISO
12100, ISO 10218-2, ISO/TS 15066). The tests check that the machine honours its declaration and
nothing more. Harm inside the envelope, sensing performance, general cybersecurity (IEC 62443) and
identity and delegation are also out of scope (`docs/requirements.md`, "Out of scope").

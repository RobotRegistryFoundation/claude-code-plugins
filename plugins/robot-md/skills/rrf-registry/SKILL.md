---
name: rrf-registry
description: >-
  Manage a robot's identity and compliance record at the Robot Registry Foundation (RRF) with the
  robot-md CLI: mint a Robot Registration Number (RRN), check registry health, rotate or revoke the
  robot's signing key, prove manufacturer identity with verify-tier, recover a lost API key, and emit
  and submit EU AI Act artifacts (FRIA, IFU, safety benchmark, incident report, EU register). Use
  when the user says "register my robot", "get an RRN", "rotate the key", "revoke this robot",
  "verify we're the manufacturer", "I lost my apikey", "are we ready to submit to the EU", "file an
  incident", or asks what the registry knows about a robot.
---

# Managing a robot at the Robot Registry Foundation

The registry gives each robot a permanent Robot Registration Number (RRN), binds it to a signing key,
and collects signed compliance artifacts against it. Every command here runs through the `robot-md`
CLI (`pip install 'robot-md[hardware]'`), which the `using-robot-md` skill covers installing.

## Ground rules

- **Registry records are public.** A registration publishes the robot's name, manufacturer, model,
  firmware version, RCAN version and public signing key at `https://rcan.dev/r/<rrn>` under CC0.
  Before registering, confirm with the user that nothing in those fields is private, such as a
  person's name used as a robot name. The privacy policy is at https://robotmd.dev/privacy/.
- **Mutating commands are the user's call.** `register`, `rotate-key`, `revoke-key`, `verify-tier`,
  `unregister` and any `--submit` change the public record. Show the exact command, say what it will
  change, and run it only after the user agrees. `doctor` and `compliance status` are read-only and
  safe to run whenever they help.
- **Never print secrets into the conversation.** API keys live at `~/.robot-md/keys/<rrn>.apikey`
  (mode 600) and signing keys under `~/.robot-md/keys/`. Refer to them by path; don't `cat` them.
- **`revoke-key` is one-way.** After revocation, RRF refuses every §22–26 compliance intake for that
  RRN. Say so in plain words before running it, every time.

## Check where things stand

```bash
robot-md doctor --path ROBOT.md          # install, manifest, registry reachability, keystore
robot-md compliance status               # per-artifact readiness and the blocker list
```

`doctor` never writes files and never calls the registry's mutating endpoints. Read its table back to
the user and fix fails before anything else.

## Register a robot

```bash
robot-md validate ROBOT.md
robot-md register ROBOT.md --dry-run     # sign and print the body; nothing is sent
robot-md register ROBOT.md
```

Show the user the `--dry-run` body before the real call: it is exactly what becomes public.

On success the CLI writes the RRN into `metadata.rrn` in the manifest, stores the API key at
`~/.robot-md/keys/<rrn>.apikey`, and prints the resolver URL. The API key is returned once and not
stored server-side in plaintext. Tell the user to back up `~/.robot-md/keys/`.

`robot-md init <name> --register` does the same thing as part of first-time setup.

## Keys

| Situation | Command | Notes |
|---|---|---|
| Routine rotation, or a key may be exposed | `robot-md rotate-key <RRN>` | Signs the rotation with the old and new keys. Exit 2 means the server accepted but a local disk step failed: follow the `mv` command it prints exactly, because the server now expects the new key. |
| Robot decommissioned or key compromised beyond rotation | `robot-md revoke-key <RRN> --reason "<why>"` | One-way. A 409 means it was already revoked. |
| Remove a robot from the registry | `robot-md unregister <RRN>` | Deletes the record using the stored API key. Confirm first. |
| Signing key held, API key lost | `robot-md request-apikey` | Produces a signed reissue request. Submit it with `--submit` if the endpoint is live, or send it to RRF out of band. |

## Prove manufacturer identity

```bash
# DNS TXT proof only
robot-md verify-tier <RRN> --target manufacturer_claimed --dns-domain example.com

# DNS TXT + /.well-known/rcan-manifest.json at the RURI + signed attestation
robot-md verify-tier <RRN> --target manufacturer_verified \
  --dns-domain example.com --ruri https://example.com --attestation-file signed_attestation.json
```

The user must control the domain. Walk them through publishing the TXT record before running this.
The community tier is curated by maintainers through pull requests and can't be promoted this way.

## EU AI Act artifacts

Each `emit-*` command builds a signed artifact under `compliance/`. Adding `--submit` POSTs it to RRF.
Emit first, show the user what was produced, then submit.

| Artifact | Command |
|---|---|
| Safety benchmark | `robot-md emit-benchmarks` |
| Instructions for use (IFU) | `robot-md emit-ifu` |
| Fundamental rights impact assessment (FRIA) | `robot-md emit-fria` |
| EU database registration (Art. 49) | `robot-md emit-eu-register` |
| Incident report | `robot-md incidents record`, then `robot-md incidents report` |

`emit-eu-register` applies only to high-risk systems: it fails without `compliance.annex_iii_basis`
in the manifest and a signed FRIA alongside it. The audit log behind every submission can be checked
with `robot-md audit verify`.

**What these artifacts are and aren't.** They are evidence a provider assembles, not a conformity
assessment, a certification, or legal advice. Say that whenever the user is preparing a real
submission, and point them to their notified body or counsel for the decision.

## Bounded Embodiment results

A safety benchmark from the `bounded-embodiment` skill is a finding about one run, never a
certification, and a simulation verdict is always INCONCLUSIVE for hardware. Submit it with
`emit-benchmarks --submit` only with that framing intact.

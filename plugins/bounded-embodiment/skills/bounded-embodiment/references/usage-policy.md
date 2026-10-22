# The Usage Policy's hardware requirements

Source: Anthropic's Usage Policy, <https://www.anthropic.com/legal/aup>, effective 12 November 2026,
announced at <https://www.anthropic.com/news/2026-usage-policy-update>. This page paraphrases the
policy as it read on 22 October 2026. Policies change, so read the policy itself and quote it when the
wording matters. Nothing here is legal advice, and you shouldn't give any.

## What the policy covers

The requirements cover "High-risk Physical Actions". They apply when hardware or connected equipment
acts on model outputs without human approval, and the equipment can do any of these:

- move through shared space;
- apply force that could injure someone;
- control hazardous energy or materials;
- act on the human body;
- control safety systems;
- run industrial processes where a fault could injure workers or the public.

The policy lists exclusions for physical actions:

- consumer and household devices operating within the manufacturer's built-in safety limits, where
  the worst outcome is discomfort or inconvenience;
- generating plans, code, toolpaths, waypoints or commands that a qualified person reviews before
  they are executed on equipment;
- monitoring, sensing or reporting on equipment without controlling it;
- laboratory automation that handles non-hazardous materials inside enclosed instruments.

Whether a given use is in scope, or falls under an exclusion, is for the user or deployer to decide
from the policy text. It isn't yours to decide.

## What it requires

1. **Human control.** A qualified individual must be able to observe the equipment's operation and
   stop it at any time.
2. **A safe state.** The equipment must stop or hold a safe state when that individual intervenes,
   or when the connection to Anthropic's services is lost.
3. **Independent limits.** Any operating limits that keep the equipment within safe bounds must be
   enforced by the equipment, or by a controller independent of model output. The policy's examples
   are speed, force, reach, temperature, pressure, voltage, energy output, dose and operating area.
4. **Alongside the law.** For physical devices, the requirements don't replace vehicle, aviation,
   medical device, machinery or workplace safety law or certification.

The policy doesn't require any particular test, evidence or standard.

The same section has a prohibition reminder: the Universal Usage Standards prohibit actions related
to weapons, critical infrastructure, violence and surveillance. Meeting the hardware requirements
never makes a prohibited use acceptable.

## What Bounded Embodiment can and can't speak to

| Policy requirement | Closest method requirement | What method v0.1 offers |
|---|---|---|
| 3. Limits enforced independently of model output | R2: a safety function below the model, which has no write path to the gate, the envelope or the log | **EV-03.** Evidence for one run that the declared workspace zones and speed limits held while a seeded hostile stream stood in for the model, measured by an external instrument. It covers position and speed of declared points only. Force, joint limits, acceleration and the policy's other examples are untested in v0.1. |
| 2. Stop or hold a safe state on intervention or loss of connection | R3: stop always wins, and loss of power, communications or heartbeat leads to the declared safe state | **Nothing tested yet.** The envelope declares `stop`, `heartbeat` and per-source stop limits (including `comms_loss` and `heartbeat_loss`), but v0.1 tests none of them. Method v0.1 defines only EV-03 and EV-10. EV-02 (stop performance for each stop source, at top speed) and EV-05 (the model process dies) are scope only (`docs/requirements.md`). |
| 1. A qualified individual can observe and stop | None | **Not tested.** The method's §6 requires an operator and an independent hardware stop for its own test runs. That is safety during a test, not evidence about a deployment. |
| 4. Law and certification | None | **Out of scope.** A verdict is a finding about one run, never a certification, and never evidence for one. |

## Answering "does my robot meet the Usage Policy?"

1. Point to the policy and its effective date, and don't restate it as legal advice.
2. Say what the method can give: an EV-03 run is evidence about requirement 3, for one run.
   Describe it as self-run, with illustrative thresholds, and not reproduced until another lab
   reproduces it.
3. Say what it can't give. Method v0.1 says nothing about requirements 1 and 2, nothing about force
   and most of the other listed limits, and nothing about whether the use is in scope or meets the
   policy.
4. Meeting the policy is the deployer's responsibility, and no test result settles it.

Never call a machine, gate, deployment or result "compliant", "AUP-compliant" or "approved", and
never say it "meets the Usage Policy" or is "certified".

## How Claude Code fits

The policy's exclusions include generating plans, code or commands that a qualified person reviews
before they are executed on equipment. This skill's hand-over rule follows the same pattern. You
prepare the commands or tool calls, MCP motion tools included, and a person at the machine reviews and
runs them. Whether a particular use
falls under that exclusion is still the deployer's call.

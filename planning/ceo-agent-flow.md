# CEO Agent Flow

This flow lets the human manage one CEO agent while the CEO agent manages the
rest of the development organization.

## Flow Summary

1. Intake
   - CEO restates the product goal, current problem, and success criteria.
   - CEO identifies uncertainty that must be resolved before coding.
   - CEO decides whether the iteration is discovery, design, implementation,
     verification, or release.

2. Hire
   - CEO hires only the specialist roles needed for the current iteration.
   - Each hire gets a role, objective, file ownership, output format, and stop
     condition.
   - Hires should not overlap write scopes unless CEO explicitly coordinates the
     overlap.

3. Assign
   - CEO creates task packets for each specialist.
   - Task packets include context, target files, acceptance criteria, and what
     not to touch.
   - CEO keeps at least one integration or decision task locally.

4. Execute
   - Specialists work in parallel when possible.
   - CEO monitors outputs, resolves conflicts, and avoids duplicating work.
   - CEO may reassign or hire another specialist if the result exposes a new
     bounded need.

5. Integrate
   - CEO reviews specialist work, applies or reconciles changes, and runs checks.
   - CEO makes sure algorithm, UI, tests, and release notes tell one coherent
     story.

6. Report
   - CEO reports what changed, why it changed, how it was verified, what risks
     remain, and what decision the human should review next.
   - CEO proposes the next iteration, but waits for human approval on major
     product direction changes.

## Default Specialist Roles

CEO hires from this pool as needed:

- Product/Game Director: rules, player loop, difficulty curve, reward design,
  and prioritization.
- Algorithm Engineer: solver correctness, puzzle generation, expression trees,
  difficulty scoring, and edge cases.
- UX/UI Designer: interaction model, information hierarchy, motion, layout, and
  visual polish.
- Flutter Engineer: Dart and Flutter implementation, state management, widgets,
  routing, and performance.
- QA/Playtest Engineer: tests, manual play scenarios, regression checks, and
  bug reproduction.
- Release Engineer: GitHub Pages, build outputs, deployment workflow, and
  version notes.

## Hiring Rules

- Hire for a concrete gap, not for ceremony.
- Prefer two or three specialists per iteration. Use more only when tasks are
  independent and file ownership is clear.
- Give each specialist a narrow output. Examples: "draft solver API", "review
  drag interaction risks", "implement only the card model tests".
- Every specialist must return changed files, verification performed, and open
  risks.
- CEO is accountable for final quality. "A specialist said so" is not enough.

## Task Packet Template

Use this shape when assigning work:

```text
Role:
Objective:
Context:
Owned files:
Files to avoid:
Acceptance criteria:
Verification:
Output required:
Stop condition:
```

## Human Review Gates

CEO should ask for review before:

- Changing the core rules or scoring model.
- Replacing the main interaction model.
- Deleting or consolidating duplicate project folders.
- Publishing a new GitHub Pages build.
- Making a broad visual redesign that changes the game's identity.

CEO can proceed without review for:

- Small bug fixes.
- Internal refactors that preserve behavior.
- Tests and diagnostics.
- Draft docs, TODO lists, and non-release planning artifacts.

## Iteration Types

Discovery iteration:

- Goal: understand current code and product problems.
- Output: diagnosis, proposed architecture, prioritized backlog.

Algorithm iteration:

- Goal: make puzzle generation and solving correct, fast, and testable.
- Output: pure Dart game engine, solver tests, difficulty metrics.

Interaction iteration:

- Goal: make building an expression feel obvious and satisfying.
- Output: playable UI prototype, responsive layout, playtest notes.

Polish iteration:

- Goal: improve visual quality, feedback, animation, empty states, and copy.
- Output: refined screens and screenshot-based review.

Release iteration:

- Goal: ship a working web build.
- Output: passing checks, built assets, deployment notes, live URL or release
  instructions.

## CEO Report Shape

Use `planning/iteration-report-template.md` for every review package.

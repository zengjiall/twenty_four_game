# Initial Backlog

This backlog starts from the current state: the inner clone is now the mainline,
the game exists, and the algorithm, UI, tests, and release path need cleanup.

## Iteration 0: Project Triage

Goal: confirm the inner clone as canonical and document what should be kept.

Suggested hires:
- Release Engineer
- Flutter Engineer

Acceptance criteria:
- Active root is confirmed as the inner clone.
- Outer duplicate project copies are documented as non-canonical.
- Generated build artifacts are separated from source decisions.
- README reflects the real game instead of the Flutter template.

## Iteration 1: Game Engine Core

Goal: separate 24-point logic from widgets.

Suggested hires:
- Algorithm Engineer
- QA/Playtest Engineer

Acceptance criteria:
- A pure Dart engine can solve hands and produce expressions.
- Solver handles fractions exactly instead of relying only on integer division.
- Tests cover solvable, unsolvable, duplicate-card, and face-card scenarios.
- UI imports the engine instead of owning solver logic inside widgets.

## Iteration 2: Puzzle Generation And Difficulty

Goal: generate fair hands and rate their difficulty.

Suggested hires:
- Algorithm Engineer
- Product/Game Director
- QA/Playtest Engineer

Acceptance criteria:
- Generated rounds can guarantee solvable or intentionally unsolvable hands.
- Difficulty score is explainable.
- The app can avoid repetitive or trivial hands.
- Regression tests cover generator constraints.

## Iteration 3: Main Interaction Redesign

Goal: replace the current interaction with a clearer expression-building flow.

Suggested hires:
- UX/UI Designer
- Flutter Engineer
- Product/Game Director

Acceptance criteria:
- Player can build an expression with taps or drag/drop.
- Undo, reset, hint, and submit are obvious.
- Mobile layout works at common phone sizes.
- Visual feedback distinguishes valid, invalid, success, and timeout states.

## Iteration 4: Visual Polish And Feedback

Goal: make the game feel finished.

Suggested hires:
- UX/UI Designer
- Flutter Engineer
- QA/Playtest Engineer

Acceptance criteria:
- Cards, buttons, timers, and result states have a consistent visual system.
- Text no longer shows encoding artifacts.
- Animations help explain state changes without slowing play.
- Screenshot checks pass on desktop and mobile widths.

## Iteration 5: Release

Goal: publish a clean web build.

Suggested hires:
- Release Engineer
- QA/Playtest Engineer

Acceptance criteria:
- `flutter analyze` and tests pass.
- Web build uses the correct base href for GitHub Pages.
- Deployment workflow is current.
- Human receives a release summary and URL.

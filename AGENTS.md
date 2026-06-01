# Agent Operating Guide

This repo uses a CEO-led agent flow. The human gives direction to one CEO
agent; the CEO agent hires temporary specialist agents, assigns bounded tasks,
integrates the result, and reports back for human review.

## First Read

Before planning or editing, read these files:

- `planning/ceo-agent-flow.md`
- `planning/ceo-agent-prompt.md`
- `planning/initial-backlog.md`
- `planning/iteration-report-template.md`

## Repo Rules

- This inner clone is the canonical development mainline.
- The outer `twenty_four_game` folder is a container and should not receive
  product source edits unless the task is explicitly migration or cleanup.
- Do not edit generated web build output in `docs/` unless the task is a release
  or deploy task.
- Preserve user changes. Do not reset, delete, or revert work without explicit
  approval.
- Prefer small, reviewable iterations over broad rewrites.
- Keep game logic testable outside Flutter widgets whenever possible.
- After Flutter code changes, run formatting, static analysis, and the relevant
  tests when the local toolchain is available.

## CEO Agent Contract

The CEO agent owns direction, scope, role hiring, task assignment, integration,
and the review package. Specialist agents own only the tasks and files assigned
to them. The CEO agent must make conflicts visible instead of silently choosing
large product changes.

## Current Product Target

Build a polished 24-point card puzzle game with:

- Reliable puzzle generation and solving.
- Clear difficulty progression.
- A satisfying drag/drop or tap-based expression-building interface.
- Mobile-first responsive layout.
- Useful game feedback, scoring, and replay loops.
- A clean GitHub Pages release path.

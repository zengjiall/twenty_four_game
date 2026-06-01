# Scoring And Innovation Options

This note captures the current CEO/product direction for moving the game from a
single 24-point puzzle into a replayable card-game loop. It is informed by two
references: Balatro positions itself as a poker roguelike with game-changing
Jokers and combo scoring, while Blackjack keeps the table language simple with
hit, stand, split, and Aces valued as 1 or 11.

Sources:
- Balatro official site: https://www.playbalatro.com/
- Pagat Blackjack rules: https://www.pagat.com/banking/blackjack.html

## Immediate Scoring Schemes

### Option A: Clean Practice Score

Best for the current LAN mobile test.

Formula:
- success: 100 base points
- time bonus: +1 point per second remaining
- clean bonus: +30 if every intermediate result is an integer
- variety bonus: +20 if at least three different operators are used
- no-solution claim: +80 only when the hand is actually unsolvable

Why it works:
- Easy to explain.
- Rewards speed without making time the whole game.
- Starts training players to care about style, not only correctness.

### Option B: Combo Multiplier Score

Best first step toward a Balatro-like feel.

Formula:
- base chips: target solved = 100
- multiplier starts at x1.0
- all-integer path: +0.5x
- division produces an integer: +0.3x
- final operation is multiplication or division: +0.2x
- three unique operators: +0.4x
- each Joker can add chips, multiplier, or special triggers

Why it works:
- Gives satisfying score explosions.
- Lets future Joker cards change score without rewriting core rules.
- Makes multiple solutions feel meaningfully different.

### Option C: Blackjack Pressure Score

Best if we add hit/stand later.

Formula:
- start with three cards and a stake.
- Stand early for a high multiplier.
- Hit to draw more cards, but each extra card lowers multiplier.
- Bust state is not over 21; it is "too many cards or no legal route".
- A can be 1 or 11 when this mode is enabled.

Why it works:
- Imports the readable Blackjack verbs without copying Blackjack wholesale.
- Creates quick mobile choices: hit, stand, solve, claim no solution.
- Makes risk visible before the math puzzle begins.

## Innovation Roadmap

### MVP 1: Polished Solvable Practice

Keep the current four-card, three-operation rule.

Add:
- result cards with a star suit so generated cards still feel like cards.
- timeout answer reveal.
- no-solution claim button, ready for future random/unsolvable mode.
- larger mobile drop slots and card pile.
- a more interesting score formula from Option A.

### MVP 2: Style Bonuses And Small Jokers

Add 8-12 passive Joker cards that mostly affect scoring.

First candidates:
- Accountant: integer division gives a multiplier bonus.
- Clean Table: all intermediate results are integers.
- Dealer's Favor: first operation result gets +1 once per round.
- Three-Color Math: use three different operators for a bonus.
- Tuning Fork: one card may be treated as value -1 or +1.
- Late Bloom: final operation gives a large bonus.

### MVP 3: Variable Targets

Targets become part of the run.

Examples:
- 21: easier, lower reward.
- 24: standard.
- 36: harder, higher reward.
- 22-26 range: any result in range succeeds, closer to 24 scores higher.

### MVP 4: Blackjack-Inspired Branch

Add a mode rather than changing the core practice mode.

Mechanics to test:
- Hit: draw one more card, reduce multiplier.
- Stand: lock the hand and solve.
- A as 1 or 11.
- Split pairs into two challenges only after the core loop is stable.

## Recommended Next Decision

Use Option A in the near term, then refactor it into Option B once Jokers exist.
Do not add split or complex face-card powers until mobile readability and the
basic scoring loop feel good.

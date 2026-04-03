# Personal Finance Companion – Flutter

## Overview
Brief explanation of the app and how it solves the assignment.

## Setup & Run
- Flutter 3.x
- `flutter pub get`
- `flutter run`

## Architecture
- Riverpod + Hive
- Repository pattern
- Feature‑based folder structure

## Key Decisions
- Why Hive? (fast, no migrations, perfect for local finance data)
- Why Riverpod? (reactive, testable, minimal boilerplate)
- Goal feature: "Smart Monthly Savings Goal" – uses actual income/expense to show progress.

## Assumptions
- Currency = USD (but can be changed in one place)
- Start with 3 sample transactions for demo (or empty state)
- Goal resets monthly (but for simplicity, manual reset by user)

## Demo
[Link to a 1‑min Loom video or GIF]

## Time Spent
~8 hours (shows efficiency)
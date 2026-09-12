<!-- docs/onboarding-wizard.md -->

# Onboarding wizard

## Demo

The three-step synthetic onboarding form persists each next/back transition, resumes safely, conditionally requests a compliance contact, and requires review before submission.

## Ruby

`Onboarding::SaveDraft` is the only mutation boundary. It scopes drafts to the signed-in administrator, applies step-aware model validation, and rejects stale lock versions instead of overwriting another editor.

## JavaScript

React presents progress, conditional fields, preserved values, review, and focused server errors. It proposes transitions; it does not define them.

## Architecture

The workflow is deliberately application-specific. Rails owns durable state and final meaning, while `activeadmin-react` only mounts the island. The ordinary ActiveAdmin form remains available without JavaScript.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com

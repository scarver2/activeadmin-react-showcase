<!-- docs/relationship-explorer.md -->

# Relationship and CRM Explorer

The Relationship Explorer demonstrates useful master-detail navigation over
synthetic Accounts and Contacts without turning React into a second application
or inventing a general CRM framework.

## Domain boundary

Account and Contact are the only durable nouns in this slice. Rails owns their
validation, normalized SQLite persistence, authentication, filtering, result
bounds, and resource URLs. The React island owns only transient filter and
selection interaction. Pipelines, campaigns, activities, and write workflows
remain excluded until a focused feature demonstrates real product value.

All seeded names and contact details are fictional. Email addresses use the
reserved `.example` domain. This global admin demonstration is not a
tenant-isolation template, and real contact data would require a separate
privacy, authorization, retention, and audit review.

## Data flow and bounds

1. ActiveAdmin renders a six-account relationship summary that remains useful
   without JavaScript.
2. The island requests an authenticated Rails JSON endpoint with optional
   account/contact text, plan, region, relationship-role, and selected-account
   controls.
3. `Showcase::RelationshipExplorer` allowlists every choice, caps search text at
   80 characters, and returns no more than 20 accounts per request.
4. Rails returns synthetic account/contact attributes plus Rails-generated
   resource links. React renders loading, error, empty, and populated states.

The search covers account names and contact first names, last names, email
addresses, and job titles. Filtering and persistence never move into the
browser.

## Verification

- RSpec proves model constraints, authentication, allowlisted filters, search,
  selection, result bounds, empty results, fallback content, and Rails links.
- Vitest proves loading, populated, empty, error, retry, timeout, filtering,
  navigation, truncation, and unmount cleanup states.
- Playwright proves the complete seeded flow and contact navigation against the
  real Rails application in Chromium.

This feature uses only application-specific models and adapters. It adds no
dependency or speculative primitive to
[`activeadmin-react`](https://github.com/scarver2/activeadmin-react).

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com

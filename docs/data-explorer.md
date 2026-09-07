<!-- docs/data-explorer.md -->

# Account Data Explorer

The Account Data Explorer demonstrates a headless TanStack Table inside an
ActiveAdmin page while keeping query authority in Rails.

## Data flow

1. ActiveAdmin renders a meaningful account summary and the React mount.
2. The island requests an authenticated JSON endpoint with page, page size,
   query, plan, status, sort, and direction controls.
3. `Showcase::AccountExplorer` validates every control against fixed bounds and
   allowlists before composing an Active Record relation.
4. Rails returns rows, totals, filter options, resource URLs, and pagination
   state. TanStack Table renders the semantic table but never executes queries.

Pages are capped at 100, page sizes at 5/10/20, and text queries at 80
characters. Only account name, plan, region, and status can be sorted. No SQL,
arbitrary column name, or tenant credential crosses the browser boundary.

## Verification

- RSpec proves authentication, filtering, sorting, pagination, aggregation,
  empty results, and rejected query controls.
- Vitest proves loading, populated, empty, error, retry, timeout, filtering,
  pagination, and sorting behavior at 100% component coverage.
- Playwright proves the complete interaction against seeded Rails data in real
  Chromium.

TanStack Table remains a Showcase dependency. This example does not add a data
grid abstraction to `activeadmin-react`.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com

<!-- docs/security.md -->

# Security

The eventual public showcase uses synthetic, resettable data and authenticated
administration. No customer data or production credentials belong here.

Seeded relationship contacts are fictional and use reserved `.example` email
domains. They demonstrate authenticated navigation, not production PII handling
or tenant isolation. Real contact data requires a focused authorization,
privacy, retention, and audit design.

- Keep Rails and registry secrets outside Git.
- Rate-limit publicly reachable mutation and streaming endpoints before launch.
- Keep arbitrary SQL, host controls, and unrestricted shells unavailable.
- Make terminal commands allowlisted and the initial agent deterministic.
- Authorize every Rails endpoint before data reaches component props or Cable.
- Add a report-only Content Security Policy after the chart/editor dependency set
  is known, then enforce it once browser coverage proves the required sources.
- Run Brakeman, Bundler Audit, npm audit, and Chromium coverage in CI.

Public hosting requires a focused abuse and reset review; the foundation alone
does not authorize deployment.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com

<!-- docs/geospatial-explorer.md -->

# Geospatial Explorer

## Demo

The ActiveAdmin page renders six deterministic Central Texas locations. Pan or zoom the credential-free MapLibre canvas, select clustered markers, or use the synchronized keyboard-accessible list. The ordinary fallback table links to the same Rails records.

## Ruby

`ShowcaseLocation` stores normalized coordinates. `Geospatial::LocationQuery` accepts only ordered, valid bounding boxes no larger than twelve degrees in either direction and returns at most 100 authorized records. Rails generates every record URL.

## JavaScript

The lazily loaded React island gives bounded GeoJSON to MapLibre. Map state, clustering, focus, and selection remain transient. Viewport changes fetch a new bounded projection and abort with the island lifecycle.

## Architecture

No API key, remote tile service, or geospatial database is required. Provider code stays in the showcase; SQLite remains authoritative and the normalized schema remains portable to PostgreSQL if measured demand warrants it.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com

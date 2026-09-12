<!-- docs/social-network.md -->

# Social Relationship Graph

## Demo

Choose two synthetic people, expand the first person’s network through three degrees, inspect mutual connections, and highlight the shortest bounded path. Cytoscape provides pan, zoom, layout, and pointer selection; the adjacent lists preserve keyboard access.

## Ruby

Rails owns identities, canonical undirected edges, authorization, record URLs, mutual-connection semantics, and breadth-first projections. Depth is capped at three, with at most 50 nodes and 100 edges.

## JavaScript

The lazily loaded Cytoscape island renders only the projection Rails returns. Layout, pan/zoom, selection, and path highlighting are transient. Loading, failure, disconnected, and empty projections remain explicit.

## Architecture

The normalized SQLite model stays database-portable and deliberately bounded. This is a recognizable social-network demonstration, not a CRM model or generic graph database layer.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com

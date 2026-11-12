# Root: Tournament Edition

A tournament build of Root for Tabletop Simulator: one self-contained save with a streamlined draft,
random seating, per-map clearing-priority markers, faction pieces baked to their final positions and
per-faction setup automation.

This repository holds what the save needs and nothing else:

- `dist/Root_Tournament_Edition.json` is the save. `dist/HOW_TO_INSTALL.md` says where to put it.
- `assets/` holds the art the save loads while you play. The save fetches these files from this
  repository through a CDN, so they must stay where they are.
- The `art` branch holds the rest of the art: the cards, boards, maps and pieces, served by GitHub
  Pages at `https://mrdrouf.github.io/root-tabletop-tournament/art/`. Files there are only ever
  added, so saves made with any version keep loading.
- `guide/RTT_Guide.pdf` is the player guide.

Development happens elsewhere; issues and questions go through the Steam Workshop page.

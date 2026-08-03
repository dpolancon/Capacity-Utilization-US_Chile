# Data Architecture

The data system has four layers:

1. source acquisition;
2. source-of-truth and provenance;
3. object construction;
4. estimation and reconstruction.

Raw source data should never be overwritten. Every constructed object must retain upstream lineage.

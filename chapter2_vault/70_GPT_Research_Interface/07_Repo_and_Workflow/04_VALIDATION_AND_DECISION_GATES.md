# Validation and Decision Gates

Every stage should write:

- validation checks;
- PASS/FAIL status;
- decision text;
- downstream authorization.

Example decisions:

- `AUTHORIZE_*`
- `BLOCK_*`
- `REQUIRE_*`

A PASS count is meaningful only when the checks test substantive conditions.

# Quickstart

## Recommended workflow
1) `make deps`
2) `make audit`
3) `make dry-run`
4) `make apply`
5) `make audit` again

## Lockout prevention tips
- Keep an open root console (cloud serial / provider console) during changes.
- Test SSH key login before disabling password auth.
- Apply in staging first.

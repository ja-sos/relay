# Resolving the spec

Two skills load this file to find what a pull request was built to deliver: `address-review`
and `self-review`. It resolves the pull request's **spec** - the issues it delivers and the
handoff it was built from, where either exists.

The caller supplies the pull request, settled by its own `pr-view`. The caller reads the routed
documents and states the resolved spec itself.

## Resolving

In order:

1. **The issues.** Run `pr-issues` on the pull request. It returns each issue the pull request
   names, with its repository, and whether the pull request delivers it or only references
   it; how a pull request names its issues is the backend's to define (`defining-backends.md`).
   Under `none` no issue is found. Run `view` on each issue returned, in the repository it
   came with.
2. **The handoff.** Run `has-handoff` on each issue found; where it resolves to `op: view`, the
   `view` output already read answers it. Read no issue twice. Follow every pointer its output
   carries - the marker with no fenced header - by running `fetch-handoff` on the locator the
   pointer carries, and add the issue the pointer names to the issues found, running `view`
   and `has-handoff` on it as on any other. An issue can carry a pointer and a handoff of its
   own; collect both. Of the handoffs collected, the binding one is the handoff whose header
   `branch` line equals the pull request's head branch, or, failing that, the head branch
   with a trailing `-<6 hex>` removed - the name `implement-handoff` substitutes where the
   handoff's branch already existed. Where several match on one issue, the one appearing last
   in `has-handoff`'s output binds. Where the matches sit on different issues, bind none.
   Where none matches and exactly one handoff was collected, it binds, unless it was reached
   only through an issue the pull request references rather than delivers. Otherwise bind
   none, and name every handoff collected in the caller's statement of the spec.
3. **What counts.** Where a handoff binds, the spec is that handoff and the issues its header
   `issue` line names; run `view` on any of those not yet read, in the repository the handoff
   was posted in. Any other issue found is context, named in the statement as not spec.
   Where none binds, the spec is the issues the pull request delivers, or the ones it only
   references where it delivers none.

## Not found

A `view` or `fetch-handoff` answering not-found - an issue that does not exist, a handoff since
deleted - is that candidate's answer, not a backend failure: drop the candidate, name it in the
statement, and go on. Any other failure, an access denial included, falls under the calling
skill's stop rule for a failed operation. The statement names a dropped issue as not found or
not readable with this session's credentials.

`has-handoff` can miss a handoff that has been delivered; an issue is a spec on its own.

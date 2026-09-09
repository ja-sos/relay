# relay

A Claude Code marketplace. Its plugins cover the places work changes hands - between sessions,
people and machines - where the context does not travel with it.

## Add it

```
claude plugin marketplace add ja-sos/relay
```

`marketplace add` also takes a path, so a clone works with no remote involved:

```
claude plugin marketplace add /path/to/relay
```

## Plugins

| Plugin | What it does |
|---|---|
| [`baton`](plugins/baton) | Carries one unit of work from a tracker issue to a finished implementation on a pull request, across sessions sharing no context. Ten skills; GitHub by default, any tracker by configuration. |

Install one with `claude plugin install <plugin>@relay`. Each plugin's own README covers what it
holds and how to configure it.

## License

MIT. See `LICENSE`.

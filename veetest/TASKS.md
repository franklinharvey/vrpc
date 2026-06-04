# veetest tasks

## MVP (done)

- [x] `VeetestSuite` / `VeetestCase` with named output
- [x] `run`, `suite`, `case`
- [x] Setup / teardown hooks
- [x] Expect helpers (`check`, `eq_*`, `contains`, `len_is`)
- [x] Self-tests in `suite_test.v`
- [x] vrpc + examples depend on `../veetest`

## Next

- [ ] `-run-only` / filter cases by name from env or flag
- [ ] Optional TAP / JSON reporter for CI
- [ ] `veetest.skip` / `veetest.only` for focused runs
- [ ] Parallel suite policy docs (V runs `test_*` in parallel per module)
- [ ] Snapshot / golden helper (file compare with diff output)
- [ ] Publish `github.com/franklinharvey/veetest` and pin vrpc to a tag

## Later

- [ ] HTTP test client helpers (server fixture, retry)
- [ ] Benchmark-style cases with timing stats
- [ ] Integration with `testsuite_begin` / `testsuite_end`

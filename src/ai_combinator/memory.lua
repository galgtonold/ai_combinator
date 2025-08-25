local memory = {
  -- Stores code and built environments as {code=..., ro=..., vars=...}
  -- This stuff can't be global (kept in `storage`?), built locally, might be cause for desyncs
  combinators = {},
  combinator_env = {} -- to avoid self-recursive tables
}

return memory
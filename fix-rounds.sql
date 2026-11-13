-- One-off cleanup for projects that ended up with more rounds used than allowed (e.g. "Round 6 of 3").
update projects set rounds_total = rounds_used where rounds_used > rounds_total;
-- Or, to reset a test project back to round 1:
-- update projects set rounds_used = 1 where name = 'test0';

---
id: sys-sql-named-queries-001
domain: systems
server: RhostMUSH
source: volundmush/rhostcode (Roleplay Logging/Scene System.txt, schema.sql)
complexity: high
tags: [sql, mysql, sqlite, named-queries, parameterized, sqlformat, schema]
date_added: "2026-03-30"
tested: false
---

# Pattern: Named SQL query attributes with parameterized binding

Store SQL query strings in named attributes (`Q.SELECT.*`, `Q.INSERT.*`, `Q.UPDATE.*`) on the system object. Call them via `mysql()` or `mysql2()` using `sqlformat()` for parameter binding with `?` placeholders. Schema lives in a companion `.sql` file.

This separates query text from execution logic, allows easy inspection/modification, and prevents SQL injection by never interpolating user input into the query string.

## Object structure

```mushcode
@create Scene System
@set Scene System=inherit safe

@@ — Schema-matching queries ——————————————————————————————————
&Q.SELECT.SCENE       #scene= SELECT id, title, status, owner FROM scene WHERE id=?
&Q.SELECT.SCENES_BY   #scene= SELECT id, title, started FROM scene WHERE owner=? ORDER BY started DESC LIMIT ?
&Q.INSERT.SCENE       #scene= INSERT INTO scene (title, status, owner, started) VALUES (?,?,?,?)
&Q.UPDATE.SCENE       #scene= UPDATE scene SET title=?, status=? WHERE id=?
&Q.DELETE.SCENE       #scene= DELETE FROM scene WHERE id=?

@@ — Convenience lookups ——————————————————————————————————————
&Q.SELECT.ACTOR_IN    #scene= SELECT actor_id FROM actor WHERE scene_id=? AND player_dbref=?
&Q.COUNT.POSES        #scene= SELECT COUNT(*) FROM pose WHERE scene_id=?
```

## Execution pattern

```mushcode
@@ Run a SELECT and get the result:
[setq(0, mysql(u(%!/Q.SELECT.SCENE), sqlformat(u(%!/Q.SELECT.SCENE),%0)))]

@@ INSERT with multiple params (scene title, status, owner, timestamp):
[mysql(u(%!/Q.INSERT.SCENE),
  sqlformat(u(%!/Q.INSERT.SCENE), %0, open, objid(%#), secs()))]

@@ Iterate over multi-row result (rows separated by |, cols by ^):
[iter(
  mysql(u(%!/Q.SELECT.SCENES_BY),
    sqlformat(u(%!/Q.SELECT.SCENES_BY), objid(%#), 10)),
  @pemit %#=[extract(%i0,1,1,^)]: [extract(%i0,2,1,^)],
  |)]
```

## Companion schema file

```sql
-- schema.sql — kept next to the .txt installer in version control

CREATE TABLE IF NOT EXISTS scene (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  title     VARCHAR(100)  NOT NULL DEFAULT '',
  status    VARCHAR(20)   NOT NULL DEFAULT 'open',
  owner     VARCHAR(30)   NOT NULL,
  started   INTEGER       NOT NULL,
  ended     INTEGER       DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS actor (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  scene_id    INTEGER NOT NULL REFERENCES scene(id),
  player_dbref VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS pose (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  scene_id    INTEGER NOT NULL REFERENCES scene(id),
  actor_id    INTEGER REFERENCES actor(id),
  body        TEXT NOT NULL,
  posed_at    INTEGER NOT NULL
);
```

## `DOSQL` helper (for fire-and-forget writes)

```mushcode
@@ On #inc: runs a query, pemits error to staff if it fails
&DOSQL #inc=
  [setq(9, mysql(u(%0), sqlformat(u(%0), %1)))]
  @switch [isnum(%q9)]=
    0, @pemit [tag(global_error_obj)]=[header(SQL ERROR)] Query=[u(%0)] Args=%1 Result=%q9
```

```mushcode
@@ Caller:
@attach %!/DOSQL=#scene/Q.INSERT.POSE, %0, objid(%#), secs()
```

## Notes

- `sqlformat(query_string, arg1, arg2, ...)` escapes each arg and substitutes `?` placeholders in order. Never use `%0` directly in the query string.
- `mysql()` returns the result as a string with rows delimited by `|` and columns by `^` (RhostMUSH default — check your server config).
- Store the query string in the attr, then pass `u(%!/Q.SELECT.*)` to both `mysql()` and `sqlformat()` — this guarantees the placeholder count matches.
- Naming convention: `Q.<VERB>.<NOUN>` (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `COUNT`, `EXISTS`).
- Keep the companion `.sql` schema file alongside the `.txt` installer in version control. The schema is the source of truth; the query attrs must stay in sync with it.
- For SQLite (RhostMUSH default), use `INTEGER PRIMARY KEY AUTOINCREMENT`; for MySQL, `INT AUTO_INCREMENT PRIMARY KEY`.

## When NOT to use

- When the query is trivial and one-off — inline is fine for quick admin queries.
- When you need dynamic column selection — build the query string carefully and still use `sqlformat()` for the WHERE values.

## @rhost/testkit snippet

```typescript
it('inserts and retrieves a scene', async ({ client }) => {
  const result = await client.command('+scene/new Test Scene');
  if (!result.some(l => l.includes('Scene #'))) throw new Error('Expected scene ID');

  const list = await client.command('+scene/list');
  if (!list.some(l => l.includes('Test Scene'))) throw new Error('Expected scene in list');
});
```

## Source

Extracted from: `Roleplay Logging/Scene System.txt`, `Roleplay Logging/schema.sql` in https://github.com/volundmush/rhostcode

/**
 * GMCCG Phase 1 — RhostMUSH Migration Tests
 * Source: https://github.com/thenomain/GMCCG (TinyMUX)
 * Target: RhostMUSH
 * Migration date: 2026-03-27
 *
 * Run with: @rhost/testkit
 *
 * Prerequisites: Phase 1 softcode installed (1a → 2d in order).
 * All tests use a fresh test character object (#TEST_SHEET) seeded via
 * the test harness before each suite.
 */

import { RhostRunner } from "@rhost/testkit";

const r = new RhostRunner();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Seed a minimal human sheet on object `obj` */
async function seedHuman(r: RhostRunner, obj: string) {
  await r.run(`&_attribute.intelligence ${obj}=2`);
  await r.run(`&_attribute.wits ${obj}=3`);
  await r.run(`&_attribute.resolve ${obj}=2`);
  await r.run(`&_attribute.strength ${obj}=2`);
  await r.run(`&_attribute.dexterity ${obj}=2`);
  await r.run(`&_attribute.stamina ${obj}=2`);
  await r.run(`&_attribute.presence ${obj}=2`);
  await r.run(`&_attribute.manipulation ${obj}=2`);
  await r.run(`&_attribute.composure ${obj}=2`);
  await r.run(`&_bio.template ${obj}=Human`);
}

// ---------------------------------------------------------------------------
// Suite 1 — Data Dictionary objects exist
// ---------------------------------------------------------------------------

r.suite("Phase 1 — Object existence", () => {
  r.test("Data Dictionary <dd> exists", async () => {
    const out = await r.eval(`t(v(d.dd))`);
    r.expect(out).toBe("1");
  });

  r.test("Data Tags <d:t> exists", async () => {
    const out = await r.eval(`t(v(d.dt))`);
    r.expect(out).toBe("1");
  });

  r.test("Stat Functions Prototype <sfp> exists", async () => {
    const out = await r.eval(`t(v(d.sfp))`);
    r.expect(out).toBe("1");
  });

  r.test("DD cross-references SFP", async () => {
    const out = await r.eval(`t(u(v(d.dd)/d.sfp))`);
    r.expect(out).toBe("1");
  });

  r.test("SFP cross-references DD", async () => {
    const out = await r.eval(`t(u(v(d.sfp)/d.data-dictionary))`);
    r.expect(out).toBe("1");
  });
});

// ---------------------------------------------------------------------------
// Suite 2 — dot-function: .Value and .Value_Full
// ---------------------------------------------------------------------------

r.suite("Phase 1 — .Value / .Value_Full", async () => {
  const obj = await r.createObject("TestSheet");
  await seedHuman(r, obj);

  r.test(".Value returns numeric base of attribute", async () => {
    const out = await r.eval(`u(v(d.dd)/.value,${obj},attribute.intelligence)`);
    r.expect(out).toBe("2");
  });

  r.test(".Value_Full returns raw attribute text", async () => {
    const out = await r.eval(`u(v(d.dd)/.value_full,${obj},attribute.wits)`);
    r.expect(out).toBe("3");
  });

  r.test(".Value on bio string returns string", async () => {
    const out = await r.eval(`u(v(d.dd)/.value,${obj},bio.template)`);
    r.expect(out).toBe("Human");
  });

  r.test(".Value_Stats sums multiple stats", async () => {
    // resolve(2) + composure(2) = 4
    const out = await r.eval(
      `u(v(d.dd)/.value_stats,${obj},attribute.resolve attribute.composure)`
    );
    r.expect(out).toBe("4");
  });
});

// ---------------------------------------------------------------------------
// Suite 3 — dot-function: .At_Least / .At_Most / .Between
// ---------------------------------------------------------------------------

r.suite("Phase 1 — .At_Least / .At_Most / .Between", async () => {
  const obj = await r.createObject("TestSheet");
  await seedHuman(r, obj);

  r.test(".At_Least: wits(3) >= 3 → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.at_least,${obj},attribute.wits,3)`
    );
    r.expect(out).toBe("1");
  });

  r.test(".At_Least: wits(3) >= 4 → 0", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.at_least,${obj},attribute.wits,4)`
    );
    r.expect(out).toBe("0");
  });

  r.test(".At_Least_All: resolve(2)>=2 AND composure(2)>=2 → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.at_least_all,${obj},attribute.resolve:2 attribute.composure:2)`
    );
    r.expect(out).toBe("1");
  });

  r.test(".At_Least_All: fails if one stat below threshold → 0", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.at_least_all,${obj},attribute.resolve:3 attribute.composure:2)`
    );
    r.expect(out).toBe("0");
  });

  r.test(".At_Least_One: resolve(2)>=3 OR wits(3)>=3 → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.at_least_one,${obj},attribute.resolve:3 attribute.wits:3)`
    );
    r.expect(out).toBe("1");
  });

  r.test(".At_Most: resolve(2) <= 3 → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.at_most,${obj},attribute.resolve,3)`
    );
    r.expect(out).toBe("1");
  });

  r.test(".Between: wits(3) between 2 and 4 → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.between,${obj},attribute.wits,2,4)`
    );
    r.expect(out).toBe("1");
  });

  r.test(".Between: wits(3) between 4 and 5 → 0", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.between,${obj},attribute.wits,4,5)`
    );
    r.expect(out).toBe("0");
  });
});

// ---------------------------------------------------------------------------
// Suite 4 — dot-function: .Has / .Has_Not / .Has_One_Of / .Has_All_Of
// ---------------------------------------------------------------------------

r.suite("Phase 1 — .Has family", async () => {
  const obj = await r.createObject("TestSheet");
  await seedHuman(r, obj);
  await r.run(`&_merit.hardy ${obj}=2`);

  r.test(".Has: merit.hardy exists → 1", async () => {
    const out = await r.eval(`u(v(d.dd)/.has,${obj},merit.hardy)`);
    r.expect(out).toBe("1");
  });

  r.test(".Has: merit.fame does not exist → 0", async () => {
    const out = await r.eval(`u(v(d.dd)/.has,${obj},merit.fame_(*))`);
    r.expect(out).toBe("0");
  });

  r.test(".Has_Not: merit.fame does not exist → 1", async () => {
    const out = await r.eval(`u(v(d.dd)/.has_not,${obj},merit.fame_(*))`);
    r.expect(out).toBe("1");
  });

  r.test(".Has_One_Of: has hardy but not fame → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.has_one_of,${obj},merit.hardy merit.fame_(*))`
    );
    r.expect(out).toBe("1");
  });

  r.test(".Has_All_Of: has hardy but not fame → 0", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.has_all_of,${obj},merit.hardy merit.fame_(*))`
    );
    r.expect(out).toBe("0");
  });
});

// ---------------------------------------------------------------------------
// Suite 5 — dot-function: .Is family
// ---------------------------------------------------------------------------

r.suite("Phase 1 — .Is family", async () => {
  const obj = await r.createObject("TestSheet");
  await seedHuman(r, obj);

  r.test(".Is: template is Human → 1", async () => {
    const out = await r.eval(`u(v(d.dd)/.is,${obj},bio.template,Human)`);
    r.expect(out).toBe("1");
  });

  r.test(".Is: template is Vampire → 0", async () => {
    const out = await r.eval(`u(v(d.dd)/.is,${obj},bio.template,Vampire)`);
    r.expect(out).toBe("0");
  });

  r.test(".Is_One_Of: template in Human.Vampire → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.is_one_of,${obj},bio.template,Human.Vampire)`
    );
    r.expect(out).toBe("1");
  });

  r.test(".Is_None_Of: template not in Vampire.Werewolf → 1", async () => {
    const out = await r.eval(
      `u(v(d.dd)/.is_none_of,${obj},bio.template,Vampire.Werewolf)`
    );
    r.expect(out).toBe("1");
  });
});

// ---------------------------------------------------------------------------
// Suite 6 — dot-function: .Sphere
// ---------------------------------------------------------------------------

r.suite("Phase 1 — .Sphere", async () => {
  const obj = await r.createObject("TestSheet");
  await r.run(`&_bio.template ${obj}=Human`);

  r.test(".Sphere: Human template → human", async () => {
    const out = await r.eval(`u(v(d.dd)/.sphere,${obj})`);
    r.expect(out).toBe("human");
  });
});

// ---------------------------------------------------------------------------
// Suite 7 — UDF registration
// ---------------------------------------------------------------------------

r.suite("Phase 1 — User-defined functions registered", () => {
  r.test("statpath() is registered as a global function", async () => {
    // If registered, calling with no args returns an error, not '#-1 NO SUCH FUNCTION'
    const out = await r.eval(`statpath()`);
    r.expect(out).not.toContain("NO SUCH FUNCTION");
  });

  r.test("getstat() is registered", async () => {
    const out = await r.eval(`getstat()`);
    r.expect(out).not.toContain("NO SUCH FUNCTION");
  });

  r.test("setstat() is registered", async () => {
    const out = await r.eval(`setstat()`);
    r.expect(out).not.toContain("NO SUCH FUNCTION");
  });

  r.test("hastag?() is registered", async () => {
    const out = await r.eval(`hastag?()`);
    r.expect(out).not.toContain("NO SUCH FUNCTION");
  });
});

// ---------------------------------------------------------------------------
// Suite 8 — Security: UseLock on system objects
// ---------------------------------------------------------------------------

r.suite("Phase 1 — Security: system object locks", () => {
  r.test("DD default lock rejects non-wizard force", async () => {
    // A mortal player should not be able to @force the DD
    const out = await r.asCharacter(
      "mortal",
      `@force ${await r.eval("v(d.dd)")}=think hi`
    );
    r.expect(out).toContain("Permission denied");
  });

  r.test("SFP default lock rejects non-wizard force", async () => {
    const out = await r.asCharacter(
      "mortal",
      `@force ${await r.eval("v(d.sfp)")}=think hi`
    );
    r.expect(out).toContain("Permission denied");
  });
});

// ---------------------------------------------------------------------------
// Suite 10 — Advantage derivation
// ---------------------------------------------------------------------------

r.suite("Phase 1 — Derived advantages", async () => {
  const obj = await r.createObject("TestSheet");
  await seedHuman(r, obj);
  // resolve=2, composure=2 → willpower_maximum=4
  // strength=2, dexterity=2, species_factor default=5 → speed=9
  // dexterity=2, composure=2 → initiative=4
  // wits=3, composure=2 → perception=5

  r.test("willpower_maximum = resolve + composure = 4", async () => {
    const out = await r.eval(
      `u(v(d.dd)/advantage.willpower_maximum,${obj})`
    );
    r.expect(out).toBe("4");
  });

  r.test("defense = athletics(0) + min(wits,dex) = min(3,2) = 2", async () => {
    const out = await r.eval(`u(v(d.dd)/advantage.defense,${obj})`);
    r.expect(out).toBe("2");
  });

  r.test("size default = 5 (no Giant/Small-Framed)", async () => {
    const out = await r.eval(`u(v(d.dd)/advantage.size,${obj})`);
    r.expect(out).toBe("5");
  });
});

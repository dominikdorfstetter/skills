---
name: write-a-skill
description: Create new agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill.
---

# Writing Skills

## Process

1. **Gather requirements** - ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle?
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?

2. **Draft the skill** - create:
   - SKILL.md with concise instructions
   - Additional reference files if content exceeds 500 lines
   - Utility scripts if deterministic operations needed

3. **Review with user** - present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Skill Structure

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template

```md
---
name: skill-name
description: Brief description of capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step processes with checklists for complex tasks]

## Advanced features

[Link to separate files: See [REFERENCE.md](REFERENCE.md)]
```

## Description Requirements

The description is **the only thing your agent sees** when deciding which skill to load. It's surfaced in the system prompt alongside all other installed skills. Your agent reads these descriptions and picks the relevant skill based on the user's request.

**Goal**: Give your agent just enough info to know:

1. What capability this skill provides
2. When/why to trigger it (specific keywords, contexts, file types)

**Format**:

- Max 1024 chars
- Write in third person
- First sentence: what it does
- Second sentence: "Use when [specific triggers]"

**Good example**:

```
Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.
```

**Bad example**:

```
Helps with documents.
```

The bad example gives your agent no way to distinguish this from other document skills.

## When to Add Scripts

Add utility scripts when:

- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

Scripts save tokens and improve reliability vs generated code.

## When to Split Files

Split into separate files when:

- SKILL.md exceeds 100 lines
- Content has distinct domains (finance vs sales schemas)
- Advanced features are rarely needed

## Repo conventions (dominiks-skills)

When adding a skill to this repo:

- Place it under the right bucket: `engineering/` (project-agnostic code work), `productivity/` (non-code workflow), `misc/` (rarely used), `personal/` (my own setup, not promoted), `deprecated/` (no longer used).
- Skills in `engineering/`, `productivity/`, `misc/` must appear in:
  - the top-level `README.md`
  - the bucket's `README.md`
  - `.claude-plugin/plugin.json`
- Skills must be **language- and framework-agnostic** — describe artifacts and layers (schema, repo, handler), not specific frameworks.
- Issue-producing skills must follow the conventions in the top-level README:
  - All issue I/O via `gh` CLI
  - Parent epic + sub-issue decomposition (parent has `- [ ] #N` checklist; sub has `Parent: #N`)
  - Test Strategy table mandatory in every issue, with a named tracer-bullet test
- Implementation guidance in any skill must reference the `tdd` skill (Pocock vertical slices, no horizontal slicing) — TDD is mandatory for any behavior change.

## Review Checklist

After drafting, verify:

- [ ] Description includes triggers ("Use when...")
- [ ] SKILL.md under 100 lines (split with REFERENCE.md if longer)
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] Concrete examples included
- [ ] References one level deep
- [ ] (If issue-producing) `gh` examples; parent + sub pattern; Test Strategy with tracer bullet
- [ ] (If implementation-producing) References the `tdd` skill; vertical slices not horizontal
- [ ] No framework names in scaffolders — describe layers, not stacks

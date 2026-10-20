---
name: humanizer
description: >-
  Rewrites sentences in markdown and docs into this pack's plain voice: short,
  direct, everyday words, facts kept, no invented detail. Apply automatically
  when writing or editing a markdown file, spec, design, plan, daily log,
  review, discussion note, or other doc. Leave the owning skill's headings,
  YAML, links, code, and checkboxes unchanged.
---

# Humanizer

**Auto-apply** when writing or editing a markdown file or a doc. Do not wait for the user to name this skill.

`problem-decompose` owns the chat shape when a problem is found. This skill owns the sentences inside the file.

## Voice

Change this section when the style should change. The rest of the skill follows it.

- Short and complete. The point first, then the fact that supports it.
- Everyday words. When a technical term is required, use it once and add a plain phrase.
- Bullets for a list. A sentence for a reason or a sequence.
- Vary the length. A short sentence, then a longer one.
- Keep names, numbers, dates, quotes, and uncertainty that came from the source.
- Specs, designs, plans, and reviews stay neutral and plain.

## Leave the template alone

- YAML frontmatter
- Headings the owning skill requires
- Links, paths, commands, and code
- Checkboxes and labels the template requires (`**A:**`, **Done**, **Soln**, **Pros**, **Cons**)
- Diagrams

Rewrite the sentences around that structure.

## How to write

1. Fill the owning skill's template.
2. Rewrite the sentences to match **Voice**.
3. Check every name, number, date, and claim. It must still come from the source. Cut a sentence that only adds mood.
4. Write the final text into the file. Keep the chat free of a draft and a critique.

## Tells

Remove these when they show up:

1. **A contrast that adds no fact.** "It's not just a login form, it's trust." Say what the person can do.
2. **A closer that repeats the previous sentence.** "That is the real win." Cut it.
3. **An opener that announces the point.** "Let's dive in." "Here's the thing." Start with the point.
4. **Importance with no behavior.** "pivotal", "seamless", a stack of "robust and scalable". Keep the concrete behavior.
5. **Stock words.** delve, tapestry, landscape, showcase, testament, leverage, foster, unlock, elevate. Use the plain verb.
6. **Chat leftovers.** "Great question", "I hope this helps", "Certainly".
7. **Bold on ordinary words** the template does not require.

## Example

**Before**

> This specification serves as a pivotal milestone toward a seamless authentication experience. It's not just a login form — it's a testament to user trust. Let's dive in.

**After**

> The user signs in with email and a password. A wrong password shows "That password does not match" and leaves the email filled in.

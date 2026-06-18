// JSON Resume (https://jsonresume.org/schema) → moderner-cv adapter.
// Header reshape lives in `json-resume-mapping.typ`; this file owns the
// body rendering. `lib.typ` wraps both in a single one-call entry point.

#import "@preview/gairm-import:0.8.1": parse as _parse, resume-schema-strict
#import "json-resume-mapping.typ": basics-to-header

// Renderer helpers (`cv-entry`, `cv-line`, …) are passed in by the
// caller in `lib.typ` to avoid a cyclic `#import "../lib.typ"` —
// `lib.typ` re-exports `from-json-resume` from this file.

// Hoisted to module scope so the regex isn't recompiled per call.
#let _ISO-YEAR-ONLY = regex("^\d{4}$")
#let _ISO-YEAR-MONTH = regex("^\d{4}-(0[1-9]|1[0-2])$")
#let _ISO-FULL = regex("^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$")

// Iso8601 → "M/YYYY" (or "D/M/YYYY" for full dates), matching the
// template/cv.typ convention. Non-ISO strings (e.g. `certificates.date`
// is `str-type` only — not iso8601-validated — so users can legitimately
// write "circa 2020" or "Spring 2023") pass through verbatim rather
// than being mangled by partial parsing.
#let _format-date(d) = {
  if d == none or d == "" { return "" }
  let s = if type(d) == str { d } else { str(d) }
  if s.match(_ISO-YEAR-ONLY) != none { return s }
  if s.match(_ISO-YEAR-MONTH) != none {
    let parts = s.split("-")
    return str(int(parts.at(1))) + "/" + parts.at(0)
  }
  if s.match(_ISO-FULL) != none {
    let parts = s.split("-")
    return str(int(parts.at(2))) + "/" + str(int(parts.at(1))) + "/" + parts.at(0)
  }
  s
}

// Open-ended ranges render as "… -- Present". A missing start with a
// present end emits just the end (avoids a leading "-- 2024-06").
#let _fmt-range(start-date, end-date) = {
  let s = _format-date(start-date)
  let e = if end-date == none or end-date == "" { "Present" } else { _format-date(end-date) }
  if s == "" and e == "Present" { [] } else if s == "" { [#e] } else { [#s -- #e] }
}

// Empty `().join(...)` is `none` in Typst — coerce to a real string so
// callers concatenating into content don't get unexpected blank cells.
#let _safe-join(arr, sep) = if arr.len() == 0 { "" } else { arr.join(sep) }


// ---- Body section emitters ----

// Work-shaped sections (work / volunteer / projects) share a date
// range + summary/highlights body. Only the heading field names differ.
// `summary-key` is the field used for the italic-leading paragraph.
// strict schema coerces JSON string values at content paths into `[#value]`,
// so an empty string `""` becomes empty content `[]` — truthy as a value
// but visually nothing. Treat it as absent for the multiline-vs-single
// dispatch so we don't print a blank italic line under the title.
#let _has-content(v) = v != none and v != [] and v != ""

// lib.typ's `cv-entry` / `cv-entry-multiline` unconditionally emit
// `emph(employer)` in the joined element list, so an empty employer
// (e.g. `references[].name` with no organisation slot, or
// `education[].institution` missing) leaves a dangling ", " in the
// rendered output. Skip the emph when empty, otherwise behave
// identically to cv-entry / cv-entry-multiline.
#let _emit-entry(r, date, title, employer) = {
  let elements = if _has-content(employer) {
    (strong(title), emph(employer))
  } else {
    (strong(title),)
  }
  (r.cv-line)(date, elements.join(", "))
}

#let _emit-multiline(r, date, title, employer, body) = {
  let elements = if _has-content(employer) {
    (strong(title), emph(employer))
  } else {
    (strong(title),)
  }
  (r.cv-line)(
    date,
    elements.join(", ") + linebreak() + text(size: 0.9em, body),
  )
}

#let _render-rich-entry(r, items, title-key, employer-key, summary-key) = {
  for it in items {
    let date = _fmt-range(
      it.at("startDate", default: none),
      it.at("endDate", default: none),
    )
    let title = it.at(title-key, default: [])
    let employer = it.at(employer-key, default: [])
    let summary = it.at(summary-key, default: none)
    let highlights = it.at("highlights", default: ())
    let has-summary = _has-content(summary)
    if not has-summary and highlights.len() == 0 {
      _emit-entry(r, date, title, employer)
    } else {
      let body = {
        if has-summary { text(style: "italic", summary) }
        if highlights.len() > 0 { list(..highlights) }
      }
      _emit-multiline(r, date, title, employer, body)
    }
  }
}

#let _work-entries(r, items) = _render-rich-entry(r, items, "position", "name", "summary")
#let _volunteer-entries(r, items) = _render-rich-entry(r, items, "position", "organization", "summary")
#let _projects-entries(r, items) = _render-rich-entry(r, items, "name", "entity", "description")

#let _education-entries(r, items) = {
  for ed in items {
    let date = _fmt-range(ed.at("startDate", default: none), ed.at("endDate", default: none))
    let study = ed.at("studyType", default: none)
    let area = ed.at("area", default: none)
    let title = if study != none and area != none {
      [#study #area]
    } else if study != none { [#study] } else if area != none { [#area] } else { [] }
    let employer = ed.at("institution", default: [])
    let score = ed.at("score", default: none)
    if score == none {
      _emit-entry(r, date, title, employer)
    } else {
      // Score becomes an extra positional in the joined elements.
      let elements = if _has-content(employer) {
        (strong(title), emph(employer), [#score])
      } else {
        (strong(title), [#score])
      }
      (r.cv-line)(date, elements.join(", "))
    }
  }
}

// Flat single-date sections (awards / certificates / publications)
// share an `cv-entry`/`cv-entry-multiline` shape — only the field
// names differ. `summary-key: none` for sections without a body field.
#let _render-flat-entry(r, items, title-key, employer-key, date-key, summary-key) = {
  for it in items {
    let date = _format-date(it.at(date-key, default: none))
    let title = it.at(title-key, default: [])
    let employer = it.at(employer-key, default: [])
    let summary = if summary-key != none { it.at(summary-key, default: none) } else { none }
    if not _has-content(summary) {
      _emit-entry(r, [#date], title, employer)
    } else {
      _emit-multiline(r, [#date], title, employer, summary)
    }
  }
}

#let _awards-entries(r, items) = _render-flat-entry(r, items, "title", "awarder", "date", "summary")
#let _certificates-entries(r, items) = _render-flat-entry(r, items, "name", "issuer", "date", none)
#let _publications-entries(r, items) = _render-flat-entry(r, items, "name", "publisher", "releaseDate", "summary")

// Skills render as `Label: kw, kw, kw` rows via cv-line so the
// fixed left column stays consistent with the rest of the CV.
#let _skills-entries(r, items) = {
  for s in items {
    let name = s.at("name", default: [])
    let keywords = s.at("keywords", default: ())
    (r.cv-line)(name, _safe-join(keywords, ", "))
  }
}

#let _languages-entries(r, items) = {
  for l in items {
    let name = l.at("language", default: [])
    let level = l.at("fluency", default: [])
    (r.cv-line)(name, level)
  }
}

#let _interests-entries(r, items) = {
  for i in items {
    let name = i.at("name", default: [])
    let keywords = i.at("keywords", default: ())
    (r.cv-line)(name, _safe-join(keywords, ", "))
  }
}

#let _references-entries(r, items) = {
  for ref in items {
    let name = ref.at("name", default: [])
    let reference = ref.at("reference", default: [])
    _emit-multiline(r, [], name, [], reference)
  }
}

// Section titles are baked in — JSON Resume doesn't carry display
// names. Callers who want different headings should call
// `from-json-resume` directly and render the body themselves.
#let _section(title, items, render, r) = {
  if items.len() == 0 { return [] }
  [
    = #title
    #render(r, items)
  ]
}

#let _body-from-resume(resume, r) = {
  let summary = resume.at("basics", default: (:)).at("summary", default: none)
  let parts = ()
  if summary != none { parts.push([#summary]) }
  parts.push(_section("Experience", resume.at("work", default: ()), _work-entries, r))
  parts.push(_section("Volunteer", resume.at("volunteer", default: ()), _volunteer-entries, r))
  parts.push(_section("Education", resume.at("education", default: ()), _education-entries, r))
  parts.push(_section("Projects", resume.at("projects", default: ()), _projects-entries, r))
  parts.push(_section("Awards", resume.at("awards", default: ()), _awards-entries, r))
  parts.push(_section("Certificates", resume.at("certificates", default: ()), _certificates-entries, r))
  parts.push(_section("Publications", resume.at("publications", default: ()), _publications-entries, r))
  parts.push(_section("Skills", resume.at("skills", default: ()), _skills-entries, r))
  parts.push(_section("Languages", resume.at("languages", default: ()), _languages-entries, r))
  parts.push(_section("Interests", resume.at("interests", default: ()), _interests-entries, r))
  parts.push(_section("References", resume.at("references", default: ()), _references-entries, r))
  parts.join()
}

// Returns `(header, body)`. Split so callers can override header
// kwargs or stitch in custom sections before rendering.
//
// `renderers` is a dict of `(cv-entry:, cv-entry-multiline:, cv-line:)`
// passed in by `lib.typ` — it can't be imported directly here without
// creating a cyclic `#import "../lib.typ"`.
#let from-json-resume(data, renderers: none) = {
  if renderers == none {
    panic(
      "from-json-resume requires `renderers:` — a dict of `(cv-entry:, cv-entry-multiline:, cv-line:)`. "
        + "Use `moderner-cv-from-json` for the one-call form.",
    )
  }
  let resume = _parse(data, schema: resume-schema-strict)
  let header = basics-to-header(resume.at("basics", default: (:)))
  let body = _body-from-resume(resume, renderers)
  (header: header, body: body)
}

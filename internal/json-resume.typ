// JSON Resume (https://jsonresume.org/schema) → moderner-cv adapter.
// Header reshape lives in `json-resume-mapping.typ`; this file owns the
// body rendering. `lib.typ` wraps both in a single one-call entry point.

#import "@preview/gairm-import:0.8.1": parse as _parse, resume-schema-strict
#import "json-resume-mapping.typ": basics-to-header

// Renderer helpers (`cv-entry`, `cv-line`, …) are passed in by the
// caller in `lib.typ` to avoid a cyclic `#import "../lib.typ"` —
// `lib.typ` re-exports `from-json-resume` from this file.

// JSON Resume permits YYYY, YYYY-MM, YYYY-MM-DD. Pass through as-is —
// the rendered date column is freeform text, not a typed date.
#let _fmt-range(start-date, end-date) = {
  let s = if start-date == none { "" } else { start-date }
  let e = if end-date == none { "Present" } else { end-date }
  if s == "" and e == "Present" { [] } else { [#s -- #e] }
}

#let _work-entries(r, items) = {
  for w in items {
    let date = _fmt-range(w.at("startDate", default: none), w.at("endDate", default: none))
    let title = w.at("position", default: [])
    let employer = w.at("name", default: [])
    let summary = w.at("summary", default: none)
    let highlights = w.at("highlights", default: ())
    let body = {
      if summary != none { text(style: "italic", summary) }
      if highlights.len() > 0 { list(..highlights) }
    }
    if summary == none and highlights.len() == 0 {
      (r.cv-entry)(date: date, title: title, employer: employer)
    } else {
      (r.cv-entry-multiline)(date: date, title: title, employer: employer, body)
    }
  }
}

#let _volunteer-entries(r, items) = {
  for v in items {
    let date = _fmt-range(v.at("startDate", default: none), v.at("endDate", default: none))
    let title = v.at("position", default: [])
    let employer = v.at("organization", default: [])
    let summary = v.at("summary", default: none)
    let highlights = v.at("highlights", default: ())
    let body = {
      if summary != none { text(style: "italic", summary) }
      if highlights.len() > 0 { list(..highlights) }
    }
    if summary == none and highlights.len() == 0 {
      (r.cv-entry)(date: date, title: title, employer: employer)
    } else {
      (r.cv-entry-multiline)(date: date, title: title, employer: employer, body)
    }
  }
}

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
      (r.cv-entry)(date: date, title: title, employer: employer)
    } else {
      (r.cv-entry)(date: date, title: title, employer: employer)[#score]
    }
  }
}

#let _awards-entries(r, items) = {
  for a in items {
    let date = a.at("date", default: [])
    let title = a.at("title", default: [])
    let employer = a.at("awarder", default: [])
    let summary = a.at("summary", default: none)
    if summary == none {
      (r.cv-entry)(date: [#date], title: title, employer: employer)
    } else {
      (r.cv-entry-multiline)(date: [#date], title: title, employer: employer, summary)
    }
  }
}

#let _certificates-entries(r, items) = {
  for c in items {
    let date = c.at("date", default: [])
    let title = c.at("name", default: [])
    let employer = c.at("issuer", default: [])
    (r.cv-entry)(date: [#date], title: title, employer: employer)
  }
}

#let _publications-entries(r, items) = {
  for p in items {
    let date = p.at("releaseDate", default: [])
    let title = p.at("name", default: [])
    let employer = p.at("publisher", default: [])
    let summary = p.at("summary", default: none)
    if summary == none {
      (r.cv-entry)(date: [#date], title: title, employer: employer)
    } else {
      (r.cv-entry-multiline)(date: [#date], title: title, employer: employer, summary)
    }
  }
}

#let _projects-entries(r, items) = {
  for p in items {
    let date = _fmt-range(p.at("startDate", default: none), p.at("endDate", default: none))
    let title = p.at("name", default: [])
    let employer = p.at("entity", default: [])
    let description = p.at("description", default: none)
    let highlights = p.at("highlights", default: ())
    let body = {
      if description != none { text(style: "italic", description) }
      if highlights.len() > 0 { list(..highlights) }
    }
    if description == none and highlights.len() == 0 {
      (r.cv-entry)(date: date, title: title, employer: employer)
    } else {
      (r.cv-entry-multiline)(date: date, title: title, employer: employer, body)
    }
  }
}

// Skills render as `Label: kw, kw, kw` rows via cv-line so the
// fixed left column stays consistent with the rest of the CV.
#let _skills-entries(r, items) = {
  for s in items {
    let name = s.at("name", default: [])
    let keywords = s.at("keywords", default: ())
    (r.cv-line)(name, keywords.join(", "))
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
    if keywords.len() == 0 {
      (r.cv-line)(name, [])
    } else {
      (r.cv-line)(name, keywords.join(", "))
    }
  }
}

#let _references-entries(r, items) = {
  for ref in items {
    let name = ref.at("name", default: [])
    let reference = ref.at("reference", default: [])
    (r.cv-entry-multiline)(date: [], title: name, employer: [], reference)
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

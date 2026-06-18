// JSON Resume (https://jsonresume.org/schema) adapter for moderner-cv.
// `from-json-resume` validates via @preview/gairm-import and remaps
// to the dict shape `moderner-cv(...)` expects (header kwargs + body
// content). The one-call `moderner-cv-from-json` wrapper lives in
// `lib.typ`, where it can compose `moderner-cv` directly.

#import "@preview/gairm-import:0.8.1": parse as _parse, resume-schema-strict

// Renderer helpers (`cv-entry`, `cv-line`, …) are passed in by the
// caller in `lib.typ` to avoid a cyclic `#import "../lib.typ"` —
// `lib.typ` re-exports `from-json-resume` from this file.

// moderner-cv's predefined `social` keys. Anything else is emitted
// as a custom 3-tuple `(faIcon, url, body)` so the link still renders.
#let _known-social-keys = ("phone", "email", "github", "linkedin", "x", "bluesky")

// FontAwesome guesses for networks not in the predefined set. Falls
// back to a generic "link" icon; users who care can post-process the
// returned dict before handing it to `moderner-cv`.
#let _network-icon = (
  twitter: "x-twitter",
  mastodon: "mastodon",
  gitlab: "gitlab",
  stackoverflow: "stack-overflow",
  youtube: "youtube",
  medium: "medium",
  facebook: "facebook",
  instagram: "instagram",
  dribbble: "dribbble",
  behance: "behance",
  twitch: "twitch",
)

#let _profile-to-social(profile) = {
  let network = profile.at("network", default: none)
  if network == none { return none }
  let key = lower(network)
  // Normalize twitter -> x to match moderner-cv's predefined key.
  if key == "twitter" { key = "x" }
  let username = profile.at("username", default: none)
  let url = profile.at("url", default: none)
  if key in _known-social-keys and username != none {
    return (key, username)
  }
  // Custom social: need an icon, a destination URL, and a body to show.
  let dest = if url != none { url } else if username != none { username } else { return none }
  let body = if username != none { username } else { url }
  let icon = _network-icon.at(key, default: "link")
  (key, (icon, dest, body))
}

#let _location-to-address(loc) = {
  if loc == none { return none }
  let parts = ()
  for k in ("address", "postalCode", "city", "region", "countryCode") {
    let v = loc.at(k, default: none)
    if v != none and v != "" { parts.push(v) }
  }
  if parts.len() == 0 { none } else { parts.join(", ") }
}

#let _basics-to-header(basics) = {
  let header = (:)
  let name = basics.at("name", default: none)
  if name != none { header.insert("name", name) }
  let label = basics.at("label", default: none)
  if label != none { header.insert("subtitle", label) }

  let social = (:)
  let phone = basics.at("phone", default: none)
  if phone != none { social.insert("phone", phone) }
  let email = basics.at("email", default: none)
  if email != none { social.insert("email", email) }
  let url = basics.at("url", default: none)
  if url != none {
    // moderner-cv has no top-level website key; use a custom social.
    social.insert("website", ("link", url, url))
  }
  for profile in basics.at("profiles", default: ()) {
    let entry = _profile-to-social(profile)
    if entry != none { social.insert(entry.at(0), entry.at(1)) }
  }
  let addr = _location-to-address(basics.at("location", default: none))
  if addr != none { social.insert("address", addr) }
  header.insert("social", social)
  header
}

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

// Returns `(header: <dict>, body: <content>)`. `header` is the named
// args for `moderner-cv.with(...)`; `body` is the trailing content.
// Split so callers can override header kwargs or stitch in custom
// sections before rendering.
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
  let header = _basics-to-header(resume.at("basics", default: (:)))
  let body = _body-from-resume(resume, renderers)
  (header: header, body: body)
}

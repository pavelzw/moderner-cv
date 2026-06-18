#import "@preview/fontawesome:0.6.0": *

#let _cv-line(left, right, ..args) = {
  set block(below: 0pt, above: 1pt)
  table(
    columns: (1fr, 5fr),
    stroke: none,
    ..args.named(),
    left,
    right,
  )
}
#let moderncv-blue = rgb("#3973AF")
#let light-gray = rgb("#737373")

#let _header(
  title: [],
  subtitle: [],
  image: none,
  image-frame-stroke: auto,
  color: moderncv-blue,
  subtitle-color: light-gray,
  socials-color: light-gray,
  emphasize: false,
  socials: (:),
) = {
  let subtitle-emphasis = "normal"
  if emphasize {
    subtitle-emphasis = "italic"
  }

  let titleStack = stack(
    dir: ttb,
    spacing: 1em,
    text(size: 30pt, title),
    text(size: 20pt, subtitle, style: subtitle-emphasis, fill: subtitle-color),
  )

  let social(icon, link_prefix, username) = [
    #if emphasize [
      #emph[#text(socials-color)[#fa-icon(icon) #link(
          link_prefix + username,
        )[#username]]]
    ] else [
      #text(socials-color)[#fa-icon(icon) #link(
          link_prefix + username,
        )[#username]]
    ]
  ]

  let custom-social(icon, dest, body) = [
    #if emphasize [
      #emph[#text(socials-color)[#fa-icon(icon) #link(dest, body)]]
    ] else [
      #text(socials-color)[#fa-icon(icon) #link(dest, body)]
    ]
  ]

  let address-social(icon, body) = [
    #if emphasize [
      #emph[#text(socials-color)[#fa-icon(icon) #body]]
    ] else [
      #text(socials-color)[#fa-icon(icon) #body]
    ]
  ]

  let socialsDict = (
    // key: (faIcon, linkPrefix)
    phone: ("phone", "tel:"),
    email: ("envelope", "mailto:"),
    github: ("github", "https://github.com/"),
    linkedin: ("linkedin", "https://linkedin.com/in/"),
    x: ("x-twitter", "https://twitter.com/"),
    bluesky: ("bluesky", "https://bsky.app/profile/"),
  )

  let socialsList = ()
  for entry in socials {
    assert(type(entry) == array, message: "Invalid social entry type.")
    assert(entry.len() == 2, message: "Invalid social entry length.")
    let (key, value) = entry
    if type(value) == str {
      if (key == "address") {
        socialsList.push(address-social("house", value))
      } else {
        if key not in socialsDict {
          panic("Unknown social key: " + key)
        }
        let (icon, linkPrefix) = socialsDict.at(key)
        socialsList.push(social(icon, linkPrefix, value))
      }
    } else if type(value) == array {
      assert(value.len() == 3, message: "Invalid social entry: " + key)
      let (icon, dest, body) = value
      socialsList.push(custom-social(icon, dest, body))
    } else {
      panic("Invalid social entry: " + entry)
    }
  }

  let socialStack = stack(
    dir: ttb,
    spacing: 0.5em,
    ..socialsList,
  )

  let imageStack = []

  if image != none {
    let imageFramed = []

    if image-frame-stroke == none {
      // no frame
      imageFramed = image
    } else {
      if image-frame-stroke == auto {
        // default stroke
        image-frame-stroke = 1pt + color
      } else {
        image-frame-stroke = stroke(image-frame-stroke)
        if image-frame-stroke.paint == auto {
          // use the main color by default
          // fields on stroke are not yet mutable
          image-frame-stroke = stroke((
            paint: color,
            thickness: image-frame-stroke.thickness,
            cap: image-frame-stroke.cap,
            join: image-frame-stroke.join,
            dash: image-frame-stroke.dash,
            miter-limit: image-frame-stroke.miter-limit,
          ))
        }
      }
      imageFramed = rect(image, stroke: image-frame-stroke)
    }

    imageStack = stack(
      dir: ltr,
      h(1em),
      imageFramed,
    )
  }

  stack(
    dir: ltr,
    titleStack,
    align(
      right + top,
      socialStack,
    ),
    imageStack,
  )
}

#let moderner-cv(
  name: [],
  subtitle: [CV],
  social: (:),
  color: moderncv-blue,
  subtitle-color: light-gray,
  socials-color: light-gray,
  emphasize-header: false,
  lang: "en",
  font: "New Computer Modern",
  image: none,
  image-frame-stroke: auto,
  paper: "a4",
  margin: (
    top: 10mm,
    bottom: 15mm,
    left: 15mm,
    right: 15mm,
  ),
  show-footer: true,
  body,
) = [
  #set page(
    paper: paper,
    margin: margin,
  )
  #set text(
    font: font,
    lang: lang,
  )

  #show heading: it => {
    set text(weight: "regular")
    set text(color)
    set block(above: 0pt)
    _cv-line(
      [],
      [#it.body],
    )
  }
  #show heading.where(level: 1): it => {
    set text(weight: "regular")
    set text(color)
    _cv-line(
      align: horizon,
      [#box(fill: color, width: 28mm, height: 0.25em)],
      [#it.body],
    )
  }

  #_header(
    title: name,
    subtitle: subtitle,
    image: image,
    image-frame-stroke: image-frame-stroke,
    color: color,
    subtitle-color: subtitle-color,
    socials-color: socials-color,
    socials: social,
    emphasize: emphasize-header,
  )

  #body

  #if show-footer [
    #v(1fr, weak: false)
    #name\
    #datetime.today().display("[month repr:long] [day], [year]")
  ]
]

#let cv-line(left-side, right-side) = {
  _cv-line(
    align(right, left-side),
    right-side,
  )
}

#let cv-entry(
  date: [],
  title: [],
  employer: [],
  ..description,
) = {
  let elements = (
    strong(title),
    emph(employer),
    ..description.pos(),
  )
  cv-line(
    date,
    elements.join(", "),
  )
}

#let cv-entry-multiline(
  date: [],
  title: [],
  employer: [],
  ..description,
) = {
  let elements = (
    strong(title),
    emph(employer),
    ..description.pos(),
  )
  cv-line(
    date,
    elements.slice(0, -1).join(", ")
      + linebreak()
      + text(
        size: 0.9em,
        elements.at(-1),
      ),
  )
}

#let cv-language(name: [], level: [], comment: []) = {
  _cv-line(
    align(right, name),
    stack(dir: ltr, level, align(right, emph(comment))),
  )
}

#let cv-double-item(left-1, right-1, left-2, right-2) = {
  set block(below: 0pt)
  table(
    columns: (1fr, 2fr, 1fr, 2fr),
    stroke: none,
    align(right, left-1), right-1, align(right, left-2), right-2,
  )
}

#let cv-list-item(item) = {
  _cv-line(
    [],
    list(item),
  )
}

#let cv-list-double-item(item1, item2) = {
  set block(below: 0pt)
  table(
    columns: (1fr, 2.5fr, 2.5fr),
    stroke: none,
    [], list(item1), list(item2),
  )
}

#import "internal/json-resume.typ": from-json-resume as _from-json-resume

// Returns `(header, body)`. Split so advanced callers can override a
// single header kwarg or stitch in custom sections without re-implementing
// the body emitter.
#let from-json-resume(data) = _from-json-resume(
  data,
  renderers: (cv-entry: cv-entry, cv-entry-multiline: cv-entry-multiline, cv-line: cv-line),
)

// One-call form. Named args override header kwargs derived from `basics`;
// extra positionals are rejected to catch drift from the kwarg form.
#let moderner-cv-from-json(data, ..rest) = {
  if rest.pos().len() > 0 {
    panic(
      "moderner-cv-from-json takes one positional (`data`); pass header overrides as named arguments. Got extra positionals: "
        + repr(rest.pos()),
    )
  }
  let named = rest.named()
  // The wrapper owns `body` (it composes header + body itself); a
  // caller-supplied `body:` would collide with the trailing positional
  // and panic with a confusing duplicate-argument error.
  if "body" in named {
    panic(
      "moderner-cv-from-json controls the body. To inject custom markup, call `from-json-resume(data)` and compose `moderner-cv(...)` yourself.",
    )
  }
  let parts = from-json-resume(data)
  // Merge `social:` key-by-key (rather than whole-dict replace) so a
  // partial override doesn't silently drop the email / github / etc.
  // fields derived from `basics`. Same for any other dict-valued kwarg.
  let header = parts.header
  for (k, v) in named {
    if k == "social" and type(v) == dictionary {
      header.insert("social", (..header.at("social", default: (:)), ..v))
    } else {
      header.insert(k, v)
    }
  }
  moderner-cv(..header, parts.body)
}

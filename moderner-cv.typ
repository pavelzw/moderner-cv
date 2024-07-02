#let _cv-line(left, right, ..args) = {
  set block(below: 0pt)
  table(
    columns: (1fr, 5fr),
    stroke: none,
    ..args.named(),
    left,
    right,
  )
}
#let moderner-cv(
  name: [],
  email: [],
  social: (:),
  color: rgb("#3973AF"),
  // color: blue,
  lang: "en",
  body
) = [
  #set page(
    paper: "a4",
    margin: (
      top: 10mm,
      bottom: 10mm,
      left: 15mm,
      right: 15mm,
    ),
  )
  #set text(lang: lang)

  #show heading: it => {
    set par(justify: true)
    _cv-line(
      align: horizon,
      [#box(fill: color, width: 28mm, height: 0.25em)],
      [#it.body],
    )
  }

  #text(size: 30pt, name)

  #body
]

#let cv-line(left-side, right-side) = {
  _cv-line(
    align(right, left-side),
    par(right-side, justify: true),
  )
}

#let cv-entry(
  date: [],
  title: [],
  employer: [],
  ..description,
) = {
  let elements = (strong(title), emph(employer), ..description.pos())
  cv-line(
    date,
    elements.join(", "),
  )
}

// \cvlanguage{name}{level}{comment}
#let cv-language(name: [], level: [], comment: []) = {
  _cv-line(
    align(right, name),
    stack(dir: ltr, level, align(right, emph(comment))),
  )
}

// same as cv-computer
#let cv-double-item(left-1: [], right-1: [], left-2: [], right-2: []) = {
  set block(below: 0pt)
  table(
    columns: (1fr, 2fr, 1fr, 2fr),
    stroke: none,
    align(right, left-1), right-1, align(right, left-2), right-2,
  )
}
// todo: keep cv-computer?
#let cv-computer = cv-double-item


// TODO: adjust list style
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

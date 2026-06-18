// Pure data → data mapping from a JSON Resume document to the dict
// shape `moderner-cv(...)` expects. No Typst content emitted here —
// the rendering layer lives in `json-resume.typ`.

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

/// Map a JSON Resume `basics.profiles[]` entry to a moderner-cv
/// `social` dict pair. Predefined keys (`github`, `linkedin`, …) get
/// a bare username; everything else becomes a custom `(icon, url, body)`
/// 3-tuple. Returns `none` when there's no usable destination.
///
/// -> (str, any) | none
#let _profile-to-social(profile) = {
  let network = profile.at("network", default: none)
  if network == none { return none }
  let key = lower(network)
  // Normalize twitter → x to match moderner-cv's predefined key.
  if key == "twitter" { key = "x" }
  let username = profile.at("username", default: none)
  let url = profile.at("url", default: none)
  if key in _known-social-keys and username != none {
    return (key, username)
  }
  // Custom social: needs a destination URL and a body to display.
  let dest = if url != none { url } else { username }
  if dest == none { return none }
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

/// Build the kwargs for `moderner-cv.with(...)` from JSON Resume
/// `basics`. `basics.url` has no predefined slot in moderner-cv so it
/// surfaces as a `website` custom-social with a generic link icon.
///
/// -> dictionary
#let basics-to-header(basics) = {
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
  if url != none { social.insert("website", ("link", url, url)) }
  for profile in basics.at("profiles", default: ()) {
    let entry = _profile-to-social(profile)
    if entry != none { social.insert(entry.at(0), entry.at(1)) }
  }
  let addr = _location-to-address(basics.at("location", default: none))
  if addr != none { social.insert("address", addr) }
  header.insert("social", social)
  header
}

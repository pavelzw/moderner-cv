// Pure data → data mapping from a JSON Resume document to the dict
// shape `moderner-cv(...)` expects. No Typst content emitted here —
// the rendering layer lives in `json-resume.typ`.

// moderner-cv's predefined `social` keys (mirroring _header's
// socialsDict in lib.typ:67-75). `phone` and `email` are also
// predefined slots but they're sourced from `basics.phone` /
// `basics.email` — a profile carrying `network: "Phone"` would
// silently clobber the basics-derived entry, so we route those to
// custom-link instead of the predefined slot.
#let _basics-owned-keys = ("phone", "email")
#let _known-social-keys = ("github", "linkedin", "x", "bluesky")

// FontAwesome icons keyed by lowercased network name. Predefined
// keys are included so a known-network profile that has only a URL
// (and so can't take the username-shaped predefined path) still
// renders with its proper brand icon via the custom 3-tuple fallback.
#let _network-icon = (
  github: "github",
  linkedin: "linkedin",
  x: "x-twitter",
  bluesky: "bluesky",
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
/// `social` dict pair. Predefined keys (`github`, `linkedin`, `x`,
/// `bluesky`) get a bare username; everything else becomes a custom
/// `(icon, url, body)` 3-tuple. Returns `none` when there's no
/// usable destination, the network is empty, or the network names
/// a basics-owned slot (phone/email) which would clobber.
///
/// -> (str, any) | none
#let _profile-to-social(profile) = {
  let network = profile.at("network", default: none)
  if network == none { return none }
  let key = lower(network)
  if key == "" or key in _basics-owned-keys { return none }
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
/// First-wins for duplicate profile networks (so if a user lists both
/// `Twitter` and `X`, the first one in document order takes the slot).
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
    if entry != none and entry.at(0) not in social {
      social.insert(entry.at(0), entry.at(1))
    }
  }
  let addr = _location-to-address(basics.at("location", default: none))
  if addr != none { social.insert("address", addr) }
  header.insert("social", social)
  header
}

// Unit tests for the mapping helpers in
// `internal/json-resume-mapping.typ`. Compile this file to run:
//
//   typst compile tests/json_resume_helpers.typ /tmp/sink.pdf --root .

#import "../internal/json-resume-mapping.typ": (
  _profile-to-social, _location-to-address, basics-to-header,
)


// ---- _profile-to-social ----

// Predefined keys: bare username returned.
#assert.eq(
  _profile-to-social((network: "GitHub", username: "jane-doe", url: "https://github.com/jane-doe")),
  ("github", "jane-doe"),
)
#assert.eq(
  _profile-to-social((network: "LinkedIn", username: "jane-doe")),
  ("linkedin", "jane-doe"),
)

// twitter → x normalisation, since moderner-cv's predefined key is "x".
#assert.eq(
  _profile-to-social((network: "Twitter", username: "jane_doe")),
  ("x", "jane_doe"),
)
#assert.eq(
  _profile-to-social((network: "X", username: "jane_doe")),
  ("x", "jane_doe"),
)

// Unknown network with a known FontAwesome icon (mastodon) →
// custom 3-tuple. Body falls back to username when no URL.
#assert.eq(
  _profile-to-social((network: "Mastodon", username: "@jane@hachyderm.io", url: "https://hachyderm.io/@jane")),
  ("mastodon", ("mastodon", "https://hachyderm.io/@jane", "@jane@hachyderm.io")),
)

// Unknown network with no FontAwesome guess → generic "link" icon.
#assert.eq(
  _profile-to-social((network: "ResearchGate", username: "jdoe", url: "https://researchgate.net/jdoe")),
  ("researchgate", ("link", "https://researchgate.net/jdoe", "jdoe")),
)

// No network at all → none.
#assert.eq(_profile-to-social((:)), none)
// Empty network string → none (would otherwise create a "" social key).
#assert.eq(_profile-to-social((network: "", url: "https://x")), none)
// `Phone` / `Email` networks are basics-owned slots; skip rather than
// silently clobber `basics.phone` / `basics.email`.
#assert.eq(_profile-to-social((network: "Phone", username: "+1")), none)
#assert.eq(_profile-to-social((network: "Email", username: "x@y.com")), none)
// Known network with only URL falls to custom 3-tuple, but now picks up
// the brand icon (was previously the generic "link" icon).
#assert.eq(
  _profile-to-social((network: "GitHub", url: "https://github.com/jane")),
  ("github", ("github", "https://github.com/jane", "https://github.com/jane")),
)


// ---- _location-to-address ----

#assert.eq(
  _location-to-address((
    address: "Test Street 1",
    postalCode: "12345",
    city: "Example City",
    region: "CA",
    countryCode: "US",
  )),
  "Test Street 1, 12345, Example City, CA, US",
)
#assert.eq(_location-to-address((city: "Berlin")), "Berlin")
#assert.eq(_location-to-address(none), none)
#assert.eq(_location-to-address((:)), none)


// ---- basics-to-header ----

// `basics.url` has no predefined slot; surfaces as a `website` custom.
#assert.eq(
  basics-to-header((
    name: "Jane Doe",
    label: "Snake Specialist",
    email: "jane@example.com",
    url: "https://example.me",
  )),
  (
    name: "Jane Doe",
    subtitle: "Snake Specialist",
    social: (
      email: "jane@example.com",
      website: ("link", "https://example.me", "https://example.me"),
    ),
  ),
)

// A small empty page so typst-compile produces a valid artifact.
#set page(width: 5cm, height: 5cm)
helpers ok

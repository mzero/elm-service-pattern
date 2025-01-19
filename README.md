# A Service Pattern

In larger Elm programs, the structure is often divided into a multiple parts,
each having their own `Model` & `Msg` types, and `init`, `update`, `view`, and
`subscriptions` functions. There are common patterns for bundling up several of
these sub-components into container component. This container component does the
job of aggregating the `Model` data, wrapping and unwrapping `Msg` data, and
calling the other functions, combining the results.

A pattern this doesn't handle is a component (a help system, say) that wishes to
offer services to the sub-components (like `showHelp`), but be managed as a
single resource at the top level. (We want one help system, not several on the
page).

While a single service like this isn't so hard, it gets much more difficult if
there are multiple services, and when the services want to be able to trigger
events events back in the sub-components.

This application demonstrates techniques to handle this cleanly, and
extensibly.

> See it in action: [Run the app](https://mzero.github.io/elm-service-pattern/)

It easily supports multiple services (in linear code). It allows service
requests to have message functions (like `Html.Evnets` handlers), and trigger
those back at a later time. It allows services to make use of `port` and `Cmd`.
And services can use each other, even self or mutually recursively.

## Narrative Path

The docs have a path that layout key ideas in order. Afterward, definitely
look at the source code to see the details of how it is done.

Read at the docs in this sequence:

_If you are looking at this on github the links below won't work._ Instead,
browse over to the [elm doc preview version](https://elm-doc-preview.netlify.app/?repo=mzero%2Felm-service-pattern).

- [`SizePicker`](src/SizePicker.elm) — the interface for clients that want to use the
  size picking service
- [`Sub1`](src/Sub1.elm) — a sub-component of the main app, which uses those services
- [`Command`](src/Command.elm) — a type like `Cmd`, but that covers all the kinds of 
  requests code can make, including the service requests
- [`SizePicker.Service`](src/SizePicker/Service.elm) - the implementation of the
  service, which, for the most part is just a standard sub-component
- [`Top`](src/Top.elm) — the top component that has sub-components in the usual way,
  but also handles distributing requests to, and responses from the services


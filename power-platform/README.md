# Exportable flow definition

[`flow-definition.json`](flow-definition.json) is the full **"Get SharePoint
Permissions"** flow from [`docs/power-platform-app.md`](../docs/power-platform-app.md)
as one pasteable file, written in the same Workflow Definition Language
Power Automate cloud flows and Azure Logic Apps both use. It saves you
building the ~15 actions one at a time in the designer.

## What's confident vs. best-effort

- **Trigger, variables, loops, filter, array-append, response, and all
  `@concat`/`@join`/`@select` expressions**: this is the public, documented
  Workflow Definition Language schema — high confidence.
- **The exact internal shape of the SharePoint connector's "Send an HTTP
  request to SharePoint" action** (the `dataset`/`parameters/method`/
  `parameters/uri` field names under `OpenApiConnection`): reverse-engineered
  from how that action is known to be structured, but I have no live
  Power Automate environment to actually import and test this against — so
  there's a real chance the connector expects slightly different parameter
  key names or nesting. This is the one part most likely to need a small
  fixup after import.

If import fails or a "Send an HTTP request to SharePoint" action shows a
validation error after pasting, the fix is almost always to open that one
action in the normal designer and re-pick the site/method/URI/headers
through its UI (the values above tell you exactly what to enter) — you
don't need to redo the whole flow.

## How to import it

1. In [make.powerautomate.com](https://make.powerautomate.com), create a
   new **Instant cloud flow**, name it "Get SharePoint Permissions", and
   pick **Power Apps (V2)** as the trigger, then click **Create** (don't
   add any actions yet).
2. In the flow designer, open the **"..." (more commands)** menu → **Edit
   in advanced mode** (this switches to the JSON/code view of the flow's
   definition).
3. Select all the existing JSON and replace it with the contents of
   `flow-definition.json`.
4. Save. Power Automate will ask you to select or create a **SharePoint**
   connection for the `shared_sharepointonline` references — pick your own
   account.
5. Open each **"Send an HTTP request to SharePoint"** action once in the
   normal (non-advanced) view to confirm it shows the right site address,
   method, URI, and header — this also lets Power Automate re-validate the
   action against its real schema and catch anything the pasted JSON got
   wrong.
6. Test the flow with a real site URL before wiring it into the Power Apps
   canvas app from the main guide.

## Not included: the canvas app

The Power Apps canvas app isn't shipped as a `.msapp`/solution file for the
same reason discussed in the main guide: that format has internal
versioned template metadata I can't fabricate reliably without a live
environment to validate against, and a broken import there is harder to
partially recover from than a flow (you'd likely have to start the app
over, versus just re-picking one action). Build the app from the screens/
formulas in [`docs/power-platform-app.md`](../docs/power-platform-app.md) —
it's straightforward canvas-app work (inputs, galleries, a button calling
this flow) once the flow itself is in place.

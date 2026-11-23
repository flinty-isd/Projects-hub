# HPUK News post template: build it by hand

The page template publishers start every HPUK News post from. It gives every
post the same reading order (title, summary, main content, action required,
attachments, contact) and no author byline, so posts read as from
**HPUK News**, not from the person who published them. Who published each
post stays in Page details and version history.

`Provision-NewsSites.ps1 -CreateTemplates` builds the same template. Use these
steps when the script can't be run. For Other News, repeat them on the Other
News site and save the template as **Other News post**.

Who: a site owner or member of HPUK News publishers. Time: about 15 minutes.

## What it will look like

```
┌──────────────────────────────────────────────────────────────┐
│  [ Banner image, 16:9 ]                                       │
│  Headline: who is affected and what is happening              │
│  (published date; no author)                                  │
├──────────────────────────────────────────────────────────────┤
│  Summary                                                      │
│  One or two sentences: who is affected and what they need ... │
├──────────────────────────────────────────────────────────────┤
│  Main content                                                 │
├──────────────────────────────────────────────────────────────┤
│  Action required and deadline                                 │
├──────────────────────────────────────────────────────────────┤
│  Attachments                                                  │
├──────────────────────────────────────────────────────────────┤
│  Contact                                                      │
└──────────────────────────────────────────────────────────────┘
```

## Build it

1. **Start a post.** Go to the HPUK News site → **+ New** → **News post** →
   **Blank** → **Create post**.

2. **Title area.** Hover over the title area and select **Edit web part**
   (the pencil):
   - **Layout**: *Image and title*. **Alignment**: *Left*.
   - **Show published date**: **On**.
   - Close the pane.

3. **Remove the author byline.** In the title area, select the author name
   under the title and remove it (the **X** next to the name), so the byline
   is empty.

4. **Title.** Type: `Headline: who is affected and what is happening`
   (publishers overwrite it).

5. **Banner image (optional placeholder).** Select **Add image** in the title
   area and choose an approved HPUK brand image (Brand Guidelines V6),
   1920 x 1080 (16:9). Set the **focal point** on its subject. Publishers
   replace it; see the *hpuk-image-banner* skill for sizing their own.

6. **Five sections.** For each row below: hover under the last section,
   select the **+** on the left → **One column**; then select **+** inside it →
   **Text**. In the text box, type the heading and format it as **Heading 2**,
   press Enter, then type the prompt and make it *italic*.
   Use **One column** only: a Text web part can't go in a *Full-width* section.

   | Order | Heading 2 | Prompt (italic) |
   |---|---|---|
   | 1 | **Summary** | *One or two sentences: who is affected and what they need to know. Before publishing, open Page details and paste this into Description (emails and Teams show it), then set Department, Category and Port.* |
   | 2 | **Main content** | *The detail. Add pictures with the Image web part and video from News Videos.* |
   | 3 | **Action required and deadline** | *What readers must do, and by when. Delete this section if no action is needed.* |
   | 4 | **Attachments** | *Link files from Notices and Attachments. Delete this section if there are none.* |
   | 5 | **Contact** | *Named person and how to reach them.* |

7. **Page details.** Select **Page details** (top right). Leave **Description**,
   **Department**, **Category**, **Port**, **Expiry date** and
   **Strategy theme** empty: the publisher must choose them for each post.
   Check the defaults: **Show in News** Yes, **Status** Live, **Include in
   weekly roundup** Yes, **Urgent** No.

8. **Save as template.** Next to **Save as draft**, open the arrow and select
   **Save as template**. Name it **HPUK News post**. Don't select *Post news*:
   the template must never be published as news.

## Check it

1. **+ New** → **News post**: **HPUK News post** appears under *Saved on this site*.
2. Create a post from it: the five sections are there in order, the byline
   is empty and the published date shows.
3. Open **Page details** on the new post: the required fields are empty, and
   Show in News, Status, roundup and Urgent have their defaults. If a value
   you set on the template didn't carry over, set it on the column's default
   in Site Pages → Library settings instead.
4. Discard the test post (don't publish it).

## Change it later

**+ New** → **News post**, then in the template pane select the **...** on
*HPUK News post* → **Edit**. Make the change and select **Save page
template**. New posts use the new version; existing posts don't change.
Don't add web parts that the news flows or email digests depend on: emails,
Teams alerts and the roundup only use the title, Description and link.

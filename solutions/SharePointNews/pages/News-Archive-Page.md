# News archive page: build it on each site

From news 1.8.0.0, C1 doesn't hide expired posts. The morning after a post's
Expiry Date it turns the post into an ordinary page (Status *Expired*, Show in
News *No*, no longer a news post) and keeps it published. It drops out of
every news feed and the roundup, and this page lists it so staff can still
read it.

Build one on **HPUK News** and one on **Other News**. Who: a site owner. Time:
about 10 minutes per site.

## 1. The view (the provisioning script makes it; otherwise by hand)

Site Pages → **+ Add view** (or *All Pages* → *Create new view*) → **News
archive**, **Public**:

- **Filter**: show items when **Status** is equal to **Expired**.
- **Sort**: **First Published Date**, descending (newest first).
- **Columns**, in order: Name (linked to the page), Title, Description,
  Department, Category, Port, First Published Date, Expiry Date.
- **Item limit**: 50, *Display items in batches*.

## 2. The page

1. Site → **+ New** → **Page** → **Blank**. Title: **News archive**.
2. Add a **One column** section, then a **Text** web part:
   *Notices and news that are no longer current. They are kept for reference
   and may be out of date: check the date before acting on anything here.*
3. Add the **List** web part (it shows document libraries too):
   - **Library**: *Site Pages*. **View**: *News archive*.
   - **Show command bar**: On, so readers can **search** and **filter** by
     Department, Category or Port.
   - **Size**: Large.
4. **Publish** the page (as a page, not *Post as news*).
5. Add it to the site navigation: **Edit** the left or top menu → **+** →
   *News archive* → link to the page.
6. Optional: on the intranet home, add a Quick link *News archive* to each
   site's page.

## 3. Check it

1. With a post archived by C1 (or one set to Status *Expired* by hand on a
   test site), open the page as a **reader** account: the post is listed,
   and its link opens it.
2. The post is **not** on the site's home News web part, the intranet home,
   hub news or the next Monday roundup.
3. Searching the archive for its title, and filtering by its Port, find it.

## Notes

- Archived posts keep their Department, Category, Port and dates, so the
  filters work. Audience targeting no longer applies once a post is an
  ordinary page: anyone who can read the site can open it. A notice that
  must not be read after expiry should be unpublished by hand instead (see
  the Publisher Guide).
- Posts unpublished by C1 before 1.8.0.0 stay hidden until C1 runs once with
  **Archive unpublished expired posts** = Yes (README, decision 6c). Check
  the *left hidden* list in the expiry report first.
- Nothing is deleted. Everything stays for the 7-year retention.

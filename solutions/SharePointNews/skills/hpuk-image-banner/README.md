# HPUK SharePoint Image Creator (skill)

A SharePoint site skill for Copilot. It prepares correctly sized images for
News banners, page titles, thumbnails, Hero, Quick Links and site images.

SharePoint skills are instructions only and can't run scripts or edit image
files. So the skill works out the exact numbers (what to cover, what to add,
where to crop, the final size and the focal point) and gives the publisher:

- a short recipe to make the image in **Paint** (built into Windows)
- the SharePoint steps, including where to set the focal point
- a READY assessment

## Add it to the site

Add [`SKILL.md`](SKILL.md) as a skill on the SharePoint site. It is the only
file the skill needs.

## Optional tool

[`../../tools/image-banner/`](../../tools/image-banner) has a Python version
(`make_banner.py`, with sizes in `presets.json`) for anyone who can run Python
on a computer. It makes the image directly and writes preview sheets. The
SharePoint skill does not use it.

## Sizes to confirm

Sizes marked as Microsoft guidance weren't rechecked against Microsoft's live
page. Good-practice sizes need Communications sign-off. The desktop strip rule
(head no more than 40% of the height) is an approximation; always preview the
page before publishing.

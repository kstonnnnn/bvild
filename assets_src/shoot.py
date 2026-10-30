import asyncio, sys
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(device_scale_factor=1)
        for html,out,r in [('icon.html','icon_round.png','220'),('icon.html','icon_full.png','0')]:
            src=open(html).read().replace('__R__',r)
            await pg.set_content(src); await pg.wait_for_timeout(300)
            await pg.locator('#s').screenshot(path=out, omit_background=True)
        for html,out in [('cover.html','cover.png'),('banner.html','banner.png')]:
            await pg.set_content(open(html).read()); await pg.wait_for_timeout(300)
            await pg.locator('#s').screenshot(path=out)
        pg2 = await b.new_page(device_scale_factor=2)
        for html,out in [('cover.html','cover@2x.png'),('banner.html','banner@2x.png')]:
            await pg2.set_content(open(html).read()); await pg2.wait_for_timeout(300)
            await pg2.locator('#s').screenshot(path=out)
        await b.close()
asyncio.run(main())

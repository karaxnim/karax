Example to use multiple karax instances on the same page.

build example:

```
nim js -d:kxiname="app1" .\app1.nim
nim js -d:kxiname="app2" .\app2.nim
```

then start `index.html` in the browser.
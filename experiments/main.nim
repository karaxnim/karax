import jester,os

settings:
    staticDir = getCurrentDir()


routes:
    get "/":
        redirect(uri "scrollapp.html")

runForever()
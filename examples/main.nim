import jester,os

settings:
    staticDir = getCurrentDir()


routes:
    get "/":
        redirect(uri"login.html")

runForever()
import urllib.request
import ssl

# Ignore self-signed SSL certificate errors
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://git.vcc.local/"

print("Sending 1000 requests to git.vcc.local...")

for i in range(1000):
    try:
        urllib.request.urlopen(url, context=ctx)
        print(f"Request {i+1} sent!")
    except Exception as e:
        print(f"Error: {e}")

print("Done!")

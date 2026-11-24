import re

path = "app/android/app/src/main/AndroidManifest.xml"
with open(path, encoding="utf-8") as manifest:
    contents = manifest.read()
contents, count = re.subn(r'android:label="[^"]*"', 'android:label="Neon Dash"', contents, count=1)
if count != 1:
    raise RuntimeError("Could not set the Android app label")
with open(path, "w", encoding="utf-8") as manifest:
    manifest.write(contents)

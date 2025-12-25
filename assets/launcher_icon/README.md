Place your icon files here before running the generator.

Expected files:
- icon-foreground.png  -> Foreground image (prefer transparent background)
- icon-background.png  -> Background image (can be a color-filled PNG) or use a solid color instead
- icon-ios.png         -> Square 1024x1024 PNG for iOS App Store / iOS icons

Recommended sizes:
- Foreground: SVG or high-resolution PNG (at least 1024px)
- Background: 1024x1024 PNG or a solid color

After placing the files, run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

If you want, upload the three PNGs here and I'll run the generator for you.

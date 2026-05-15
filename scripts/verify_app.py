from playwright.sync_api import sync_playwright
import os

def run_verification():
    os.makedirs("/home/jules/verification/screenshots", exist_ok=True)
    os.makedirs("/home/jules/verification/videos", exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            record_video_dir="/home/jules/verification/videos"
        )
        page = context.new_page()
        try:
            # Navigate to the app
            page.goto("http://localhost:8080")
            page.wait_for_timeout(5000) # Wait for Flutter to load

            # Check for title or specific element
            page.screenshot(path="/home/jules/verification/screenshots/initial_load.png")

            # Since it's a Canvas-based app (Flutter Web default),
            # direct element interaction might be limited,
            # but we can verify the splash/initial screen.

            page.wait_for_timeout(2000)
            page.screenshot(path="/home/jules/verification/screenshots/verification.png")

        finally:
            context.close()
            browser.close()

if __name__ == "__main__":
    run_verification()

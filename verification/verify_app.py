from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={'width': 450, 'height': 800})
        page = context.new_page()

        # Increased wait for Flutter initialization
        page.goto("http://localhost:8080", wait_until="networkidle")
        time.sleep(15)  # Wait for splash screen and initial render

        page.screenshot(path="verification/screenshot.png")
        browser.close()

if __name__ == "__main__":
    run()

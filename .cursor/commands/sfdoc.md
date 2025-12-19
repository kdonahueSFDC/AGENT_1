Extract Salesforce documentation content from [URL] using browser automation. The Salesforce docs use heavy JavaScript rendering with custom web components and shadow DOM. Follow this comprehensive approach based on successful sfdoc.sh implementation:

Initial Setup:

Launch browser in headless mode to avoid popup windows
Navigate to the Salesforce documentation URL
Wait for network idle state: await page.waitForLoadState('networkidle')
Accept cookies if prompted (click "Accept All Cookies" button)
Wait for the page to fully load (5+ seconds for dynamic content)
CRITICAL: Operate in SILENT MODE - do NOT provide step-by-step feedback, status updates, or intermediate messages. Only show the final extracted documentation content.
Content Extraction Strategy (4-Tier Approach):

Strategy 1 - Shadow DOM Access (Primary):

const docXmlContent = document.querySelector('doc-xml-content');
if (docXmlContent && docXmlContent.shadowRoot) {
    const shadowRoot = docXmlContent.shadowRoot;
    const docContent = shadowRoot.querySelector('doc-content');
    if (docContent && docContent.shadowRoot) {
        const deeperShadowRoot = docContent.shadowRoot;
        const mainContent = deeperShadowRoot.querySelector('.main-container') || 
                          deeperShadowRoot.querySelector('main') ||
                          deeperShadowRoot.querySelector('[class*="main"]') ||
                          deeperShadowRoot;
        return mainContent.innerHTML;
    }
}
Strategy 2 - Direct Content Selectors:

const contentSelectors = [
    'main', '[role="main"]', '.content', '.article-content', 
    '.help-content', 'article', '.body', '[class*="content"]'
];

for (const selector of contentSelectors) {
    const element = document.querySelector(selector);
    if (element && element.textContent && element.textContent.length > 500) {
        // Skip cookie banners and other non-content elements
        const text = element.textContent.toLowerCase();
        if (text.includes('cookie') && text.includes('privacy')) continue;
        return element.innerHTML;
    }
}
Strategy 3 - Fallback Element Search:

const allElements = document.querySelectorAll('*');
for (const el of allElements) {
    if (el.textContent && el.textContent.length > 1000 && 
        !el.querySelector('script') && !el.querySelector('style') &&
        el.tagName !== 'SCRIPT' && el.tagName !== 'STYLE') {
        
        const text = el.textContent.toLowerCase();
        if (text.includes('cookie') && text.includes('privacy')) continue;
        
        // Look for Salesforce-specific content patterns
        if (text.includes('external client app') || 
            text.includes('metadata api') ||
            text.includes('scratch org') ||
            text.includes('salesforce help') ||
            text.includes('tooling api') ||
            text.includes('contact center')) {
            return el.innerHTML;
        }
    }
}
Strategy 4 - Body Content (Last Resort):

const body = document.body;
if (body && body.textContent && body.textContent.length > 500) {
    return body.innerHTML;
}
Implementation Pattern:

// Launch browser in headless mode
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

// Navigate and wait for network idle
await page.goto(url);
await page.waitForLoadState('networkidle');

// Accept cookies if present
try {
    await page.click('button:has-text("Accept All Cookies")');
} catch (e) {
    // No cookie banner present
}

// Wait for content to load
await page.waitForTimeout(5000);

const strategies = [
    () => { /* Strategy 1 - Shadow DOM */ },
    () => { /* Strategy 2 - Direct Selectors */ },
    () => { /* Strategy 3 - Fallback Search */ },
    () => { /* Strategy 4 - Body Content */ }
];

for (const strategy of strategies) {
    try {
        const result = strategy();
        if (result && result.success) {
            return result;
        }
    } catch (e) {
        continue;
    }
}

await browser.close();
Key Technical Details:

Headless Mode: Always use chromium.launch({ headless: true }) to avoid popup windows
Use page.waitForLoadState('networkidle') for proper loading
Skip cookie banners: text.includes('cookie') && text.includes('privacy')
Look for substantial content: textContent.length > 500 (Strategy 2) or > 1000 (Strategy 3)
Exclude scripts and styles: !el.querySelector('script') && !el.querySelector('style')
Target Salesforce-specific patterns: "metadata api", "tooling api", "contact center", etc.
SILENT MODE: Do NOT show step-by-step progress, status updates, or intermediate messages. Only display the final extracted documentation content.
Clean Browser: Always close browser with await browser.close()
Error Handling:

Try each strategy sequentially
Catch and continue on strategy failures
Always return structured result with success/failure status
Include method used, content length, and error details
Output Structure:

{
    success: true/false,
    title: document.title,
    content: extractedHTML,
    textContent: extractedText,
    url: window.location.href,
    method: 'shadow-dom|direct-selector|fallback|body-fallback',
    contentLength: content.length,
    textLength: textContent.length
}
CRITICAL REQUIREMENT:

DO NOT use sfdoc.sh script or any external tools
MUST use only browser automation tools available in the environment
MUST implement the 4-tier strategy approach above
MUST use headless mode: chromium.launch({ headless: true })
MUST use page.waitForLoadState('networkidle') for proper loading
MUST skip cookie banners and non-content elements
MUST operate in SILENT MODE - do NOT show step-by-step progress, status updates, or intermediate messages
MUST only display the final extracted documentation content
MUST always close browser: await browser.close()
NEVER fall back to external scripts or tools - persist with browser automation until successful
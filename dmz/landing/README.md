# Windows 98 Desktop Experience

A fully interactive Windows 98-style landing page built with [98.css](https://github.com/jdan/98.css). Experience the nostalgia of the late 90s web with a complete desktop environment in your browser.

## Features

### Desktop Experience
- **Teal desktop background** - Classic Windows 98 aesthetic
- **Desktop icons** - Double-click to open windows
  - About.txt - Main welcome message
  - My Computer - File explorer with tabs
  - Guestbook - Interactive visitor form
  - Links - Collection of cool retro web links

### Taskbar & Start Menu
- **Working Start button** - Opens start menu with all applications
- **Dynamic taskbar** - Shows currently open windows
- **System tray** - Volume icon and working clock
- **Start menu** - Navigate to all windows, Run dialog, Shut Down options

### Windows
All windows feature:
- **Draggable** - Click and drag title bars to move windows
- **Working controls** - Minimize, maximize, and close buttons
- **Status bars** - Information footer in each window
- **Z-index management** - Click to bring window to front

### Advanced UI Components

#### My Computer (Explorer Window)
- **Tabs** - Files, System Info, and About tabs
- **TreeView navigation** - Expandable/collapsible folder structure
  - My Computer → C:\ → Program Files, Windows, My Documents
  - Fake file system with humorous file names
- **System information** - Displays domain, OS, browser, and status
- **Animated progress bar** - System resources loading indicator
- **About section** - Credits and information

#### Guestbook Window
Complete form with all 98.css form elements:
- **Text inputs** - Name and email fields
- **Textarea** - Multi-line message input
- **Radio buttons** - How did you find this site?
- **Checkbox** - Newsletter subscription (non-functional easter egg)
- **Submit/Clear buttons** - Form controls
- **Success message** - Appears after submission (form doesn't actually save)

#### Links Window
- **External links** - Cool retro web projects
- **Webring section** - Nostalgic webring navigation (non-functional)
- **Status bar** - Shows link count

#### About Window
- **Original welcome message** - "How did you find this place?"
- **Interactive responses** - Two button choices with different messages
- **Blinking cursor** - Terminal-style animation
- **Status bar** - Domain and status information

## Technical Details

### Resource Usage
- **Extremely lightweight** - Pure HTML/CSS/JS, no frameworks
- **Static file serving** - nginx container uses <5MB RAM
- **Client-side rendering** - All UI rendering happens in the browser
- **Single HTML file** - ~700 lines including embedded styles and scripts
- **98.css from CDN** - Only external dependency (~50KB)

### Browser Compatibility
- Works in all modern browsers
- Responsive design handles mobile and desktop
- No build process required
- Zero JavaScript dependencies beyond vanilla JS

### Privacy
- **No tracking** - No analytics or cookies
- **Domain populated dynamically** - Uses `window.location.hostname`
- **Form doesn't submit** - Guestbook entries are cosmetic only
- **No backend** - Completely client-side application

## Customization

### Modify Desktop Icons
Edit the desktop icon section (lines 207-225) to add/remove icons:
```html
<div class="desktop-icon" ondblclick="openWindow('your-window-id')">
    <img src="data:image/svg+xml,..." alt="Icon">
    <div class="desktop-icon-text">Your Icon.txt</div>
</div>
```

### Add New Windows
1. Create new window div with unique ID
2. Add to start menu
3. Update JavaScript initialization if needed

### Change Colors
Modify CSS variables in the `<style>` section:
- Background: `background: #008080;` (teal)
- Window colors: Uses 98.css defaults

### Update Links
Edit the links window (lines 469-506) to change external links.

## Integration with Docker

Served via nginx:alpine container in `dmz/docker-compose.yml`:
```yaml
landing:
  image: nginx:alpine
  container_name: landing
  volumes:
    - ./landing:/usr/share/nginx/html:ro
  mem_limit: 32m
  mem_reservation: 16m
```

Routed via Traefik using `${HIDDEN_DOMAIN}` environment variable.

## Credits

- **98.css** by [Jordan Scales](https://github.com/jdan) - The excellent CSS framework
- **Icons** - Inline SVG data URIs (no external image dependencies)
- **Inspiration** - Windows 98, GeoCities, and the retro web movement

## Easter Eggs

- Try clicking "Shut Down" in the start menu
- Check out the file names in My Documents
- Look for the "Definitely_Not_Suspicious.exe" file
- Read the fine print in the guestbook checkbox

---

Made with ❤️ and nostalgia for simpler times.

© 2025 All rights reserved

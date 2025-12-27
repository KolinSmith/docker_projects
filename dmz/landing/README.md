# Retro Landing Page

A nostalgic Windows 98-styled landing page using [98.css](https://github.com/jdan/98.css).

## What is this?

A playful easter egg / landing page that greets visitors with a retro Windows 98 dialog asking "How did you find this place?"

## Features

- **98.css styling** - Authentic Windows 98 look and feel
- **Interactive responses** - Different messages based on user selection
- **System Info window** - Shows domain status
- **Blinking cursor** - Classic terminal aesthetic
- **Fully static** - Just HTML/CSS/JS, no backend needed

## How it works

- Served via nginx container in DMZ docker-compose
- Routed through Traefik using `${HIDDEN_DOMAIN}` environment variable
- SSL via Cloudflare cert resolver
- Minimal resources (static files only)

## Files

- `index.html` - Main landing page
- No other dependencies (98.css loaded from CDN)

## Customization

Edit `index.html` to:
- Change response messages
- Add more "System Info" fields
- Modify color scheme
- Add more interactive elements

## Credits

- [98.css](https://github.com/jdan/98.css) by Jordan Scales - Windows 98 CSS framework
- Inspired by the golden age of personal websites and hidden internet corners

# Frontend (React + TypeScript)

See the root `README.md` for the full picture.

```bash
npm install
npm test        # vitest
npm run build   # strict tsc + vite build
npm run dev     # http://localhost:5173, proxies /api → localhost:3000
```

Configuration lives in `.env.local` (see `.env.example`): `VITE_API_KEY` (default `demo-key`),
`VITE_API_BASE` (default: same origin via the dev proxy). `API_PROXY_TARGET` changes the proxy target.

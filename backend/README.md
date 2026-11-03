# Backend (Rails API)

See the root `README.md` for architecture, API reference and design decisions.

```bash
bundle install
bin/rails db:setup          # seeds org + `demo-key` + 30 days of rewards
bundle exec rspec
bundle exec rubocop
bin/rails s -p 3000
```

Swap the chain adapter with `CHAIN_CLIENT=<class implementing ChainClients::Base>`.

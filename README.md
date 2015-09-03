# pathogendb-dashboard

Dynamic visualizations based on data in PathogenDB.

Uses the [Dashing framework](http://shopify.github.com/dashing).

## Getting started

You'll need Ruby, [RubyGems](https://rubygems.org/), and [Bundler](http://bundler.io/) (all pre-installed on most Macs and modern Linuxes).

1. Clone this repository somewhere. `cd` into it.

2. Copy `config.dist.yaml` to `config.yaml`. Edit `config.yaml` and set options as appropriate.

3. Install required gems.

        $ bundle install

4. Run the dashboard.

        $ dashing start
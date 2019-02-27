# cloverdb.com

This repository hosts the [cloverdb.com](https://cloverdb.com) website, which uses Jekyll/GitHub Pages to generate a static website.

NOTE: The instructions below are macOS specific steps for setting up a local Jekyll/GitHub Pages development environment.

## Installing Dependencies

First make sure you have `bundler` installed:
> [sudo] gem install bundler

(Optional) Fix potential issues with the `nokogiri` library, when using Homebrew:
> brew unlink xz

Next we can install the dependencies:
> bundle install --path vendor/bundle

(Optional) Revert the `nokogiri` fix from above:
> brew link xz

(Optional) Update dependencies:
> bundle update

## Running Locally

(Optional) Configure a [GitHub API token](https://github.com/settings/tokens):
> export JEKYLL_GITHUB_TOKEN=\<your token\>

Generate the Jekyll website to run it locally:
> bundle exec jekyll serve --incremental

Now you should be able to access the website at http://127.0.0.1:4000/, hooray!

NOTE: Certain changes are ignored when using the `--incremental` flag (such as `_config.yml` changes), so you may need to run `jekyll serve` _without_ that flag!

## License

See [LICENSE.md](LICENSE.md).

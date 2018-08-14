[![Build Status](https://app.bitrise.io/app/d99a8cc679de9944/status.svg?token=4iYU6RsLSXBRMno3j3GnJg&branch=master)](https://app.bitrise.io/app/d99a8cc679de9944)
![Downloads](https://img.shields.io/github/downloads/Dids/clover-builder/total.svg)

# Clover Builder (Automated Clover Builds)

*Show your support for this project by signing up for a [free Bitrise CI account!](https://app.bitrise.io?referrer=02c20c56fa07adcb)* (this directly helps with being able to build this project)

A project that provides automated builds for every [Clover](https://clover-wiki.zetam.org) revision.

**DISCLAIMER:** These builds are automated and largely untested, so use them at your own discretion.

## Usage

This project uses [Clobber](https://github.com/Dids/clobber) for building Clover, which you can easily install yourself, as long as you have both [Xcode](https://developer.apple.com/xcode/) and [Homebrew](https://brew.sh/) installed:

> brew tap Dids/brewery  
> brew install clobber  

Clobber supports a variety of arguments, which you can view by running `clobber -h` or `clobber --help`.  
If you run `clobber` without any arguments, it'll automatically build the latest Clover revision.

## Releases

See the [Releases](https://github.com/Dids/clover-builder/releases) tab.

## License

See [LICENSE.md](LICENSE.md).

A big thank you to [Micky1979](https://github.com/Micky1979) for creating [Build_Clover](https://github.com/Micky1979/Build_Clover) (which this project as initially based around on), as well as everyone else involved (Clover developers and contributors included!).

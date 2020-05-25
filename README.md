![Bitrise](https://img.shields.io/bitrise/d99a8cc679de9944/master.svg?label=Build%20Status&style=for-the-badge&token=4iYU6RsLSXBRMno3j3GnJg)
![GitHub All Releases](https://img.shields.io/github/downloads/Dids/clover-builder/total.svg?style=for-the-badge)
![GitHub stars](https://img.shields.io/github/stars/Dids/clover-builder.svg?label=Stargazers&style=for-the-badge)

# Automated Clover Builds

A project that provides automated builds for every [Clover](https://sourceforge.net/p/cloverefiboot/wiki/Home/) revision.

**DISCLAIMER:** These builds are automated, unofficial and largely untested, so use them at your own discretion.

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

A big thank you to everyone involved in Clover development.

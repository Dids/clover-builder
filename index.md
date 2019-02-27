# What is this?

A build repository for fully automated [Clover](https://clover-wiki.zetam.org){:target="_blank"} builds.

## Latest Release

#### Link
[{{ site.github.latest_release.name }}]({{ site.github.latest_release.html_url }}){:target="_blank"}

#### Changelog
```{{ site.github.latest_release.body | markdownify | strip_html | strip_newlines | strip | xml_escape }}```

## Archived Releases

| Link | Changelog |
| --- | --- |
{% for release in site.github.releases limit:10 %}{% if release.name == nil or release.name == empty or release.html_url == nil or release.html_url == empty %}{% continue %}{% endif %}| [{{ release.name }}]({{ release.html_url }}){:target="_blank"} | ```{{ release.body | markdownify | strip_html | strip_newlines | strip | xml_escape }}``` |
{% endfor %}

[Show more..](https://github.com/Dids/clover-builder/releases){:target="_blank"}

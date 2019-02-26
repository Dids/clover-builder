# Clover DB

Easy access to automated Clover builds.
## Latest Release

#### [{{ site.github.latest_release.name }}]({{ site.github.latest_release.html_url }})
```{{ site.github.latest_release.body | markdownify | strip_html | replace: '\n', ', ' | strip | xml_escape }}```

## Older Releases

| Version | Description |
| --- | --- |
{% for release in site.github.releases %}| [{{ release.name }}]({{ release.html_url }}) | ```{{ release.body | replace: '\n', ', ' }}``` |
{% endfor %}

# Clover DB

Easy access to automated Clover builds.
## Latest Release

### [{{ site.github.latest_release.name }}]({{ site.github.latest_release.html_url }})
```{{ site.github.latest_release.body | markdownify | strip_html | strip_newlines | strip | xml_escape }}```

## Older Releases

| Version | Description |
| --- | --- |
{% for release in site.github.releases %}{% if release.name == nil or release.name == empty or release.html_url == nil or release.html_url == empty %}{% continue %}{% endif %}| [{{ release.name }}]({{ release.html_url }}) | ```{{ release.body | markdownify | strip_html | strip_newlines | strip | xml_escape }}``` |
{% endfor %}

# Clover DB

Clover DB (or Clover Builder) provides easy access to up-to-date and fully automated Clover builds.

### Latest

[{{ site.github.latest_release.name }}]({{ site.github.latest_release.html_url }})

```{{ site.github.latest_release.body | markdownify | strip_html | strip_newlines | strip | xml_escape }}```

### Archived

| Version | Description |
| --- | --- |
{% for release in site.github.releases %}{% if release.name == nil or release.name == empty or release.html_url == nil or release.html_url == empty %}{% continue %}{% endif %}| [{{ release.name }}]({{ release.html_url }}) | ```{{ release.body | markdownify | strip_html | strip_newlines | strip | xml_escape }}``` |
{% endfor %}

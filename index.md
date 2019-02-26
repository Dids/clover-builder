# Clover DB

Easy access to automated Clover builds.
## Latest Release

#### [{{ site.github.latest_release.name }}]({{ site.github.latest_release.html_url }})
* {{ site.github.latest_release.body | newline_to_br }}

## Older Releases

| Version | Description |
| --- | --- |
{% for release in site.github.releases %}| [{{ release.name }}]({{ release.html_url }}) | ```{{ release.body }}``` |
{% endfor %}

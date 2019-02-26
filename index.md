## Latest Release

{% for release in site.github.latest_release %}
#### [{{ release.name }}]({{ release.html_url }})
> {{ release.body }}
{% endfor %}

## Older Releases

| Version | Description |
| --- | --- | --- |
{% for release in site.github.releases %}
| [{{ release.name }}]({{ release.html_url }}) | {{ release.body }} |
{% endfor %}

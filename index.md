---
layout: post
---

# What is this?

An always up-to-date repository of the latest [Clover](https://clover-wiki.zetam.org){:target="_blank"} builds, built automatically with [Clobber](https://github.com/Dids/clobber).

## Latest Release

#### [{{ site.github.latest_release.name }}]({{ site.github.latest_release.html_url }}){:target="_blank"}{% highlight text %}{{ site.github.latest_release.body | markdownify | strip_html | strip | xml_escape }}{% endhighlight %}
---

## Previous Releases

{% for release in site.github.releases limit:site.release_count %}#### {% if release.name == nil or release.name == empty or release.html_url == nil or release.html_url == empty %}{% continue %}{% endif %} [{{ release.name }}]({{ release.html_url }}){:target="_blank"}{% highlight text %}{{ release.body | markdownify | strip_html | strip | xml_escape }}{% endhighlight %}
---
{% endfor %}

[Show more..](https://github.com/Dids/clover-builder/releases){:target="_blank"}

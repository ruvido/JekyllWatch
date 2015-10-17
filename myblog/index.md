---
layout: default
---

{% for post in site.posts %}

### [{{post.title}}]({{post.url}})

{% endfor %}

---

{% for page in site.pages %}
<!--  if page.path contains 'preview/' -->
{% if page.preview %}

### [{{page.title}}]({{page.url}})
{{page.path}}

{% endif %}
{% endfor %}

---

{% for page in site.pages %}

### [{{page.title}}]({{page.url}})
{{page.path}}

{% endfor %}

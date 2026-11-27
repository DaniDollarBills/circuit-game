class_name GlossaryText
extends RefCounted
## Turns a line of copy into BBCode where glossary words are tappable links,
## so every new word can be defined on the spot.
##
## Markup: [[term]] and [[term|shown]] link a term; [[=text]] shows text that is
## never auto-linked. With autolink on, the first occurrence of every other
## glossary term or alias is linked too: longest match first, whole words, any
## capitalization, with a trailing "s", "es" or "'s" allowed. Acronyms and unit
## symbols ("LED", "mA") only match with their capitals, so "led" the verb stays
## a plain word.

const LINK_COLOR := "#7C5CC4"
const SUFFIXES: PackedStringArray = ["'s", "’s", "es", "s", ""]

static var _markup := RegEx.create_from_string("\\[\\[(.+?)\\]\\]")
static var _patterns: Array[Dictionary] = []


## {bbcode, terms (linked, in order), new_terms (linked terms not in `seen`)}
static func render(text: String, seen: Dictionary, autolink := true) -> Dictionary:
	var terms := PackedStringArray()
	var linked := {}
	for m in _markup.search_all(text):
		var key := _markup_term(m.get_string(1))
		if key != "":
			linked[key] = true
	var out := ""
	var at := 0
	for m in _markup.search_all(text):
		out += _plain_part(text.substr(at, m.get_start() - at), autolink, linked, terms)
		var inner := m.get_string(1)
		if inner.begins_with("="):
			out += _escape(inner.substr(1))
		else:
			var key := _markup_term(inner)
			var shown := inner.get_slice("|", 1) if inner.contains("|") else inner
			if key == "":
				out += _escape(shown)
			else:
				out += _link(key, shown)
				if not key in terms:
					terms.append(key)
		at = m.get_end()
	out += _plain_part(text.substr(at), autolink, linked, terms)
	var fresh := PackedStringArray()
	for t in terms:
		if not seen.has(t):
			fresh.append(t)
	return {"bbcode": out, "terms": terms, "new_terms": fresh}


## The text a player reads, with the markup removed.
static func plain(text: String) -> String:
	var out := ""
	var at := 0
	for m in _markup.search_all(text):
		out += text.substr(at, m.get_start() - at)
		var inner := m.get_string(1)
		if inner.begins_with("="):
			out += inner.substr(1)
		else:
			out += inner.get_slice("|", 1) if inner.contains("|") else inner
		at = m.get_end()
	return out + text.substr(at)


## The glossary term a name refers to (a term or an alias, any capitalization),
## or "".
static func resolve(name: String) -> String:
	var n := name.strip_edges()
	if Glossary.ENTRIES.has(n):
		return n
	var lower := n.to_lower()
	if Glossary.ENTRIES.has(lower):
		return lower
	for key in Glossary.ENTRIES:
		for alias in Glossary.ENTRIES[key]["aliases"]:
			if alias.to_lower() == lower:
				return key
	return ""


static func _markup_term(inner: String) -> String:
	if inner.begins_with("="):
		return ""
	return resolve(inner.get_slice("|", 0))


## Auto-links one stretch of text outside markup.
static func _plain_part(s: String, autolink: bool, linked: Dictionary, terms: PackedStringArray) -> String:
	if not autolink:
		return _escape(s)
	var lower := s.to_lower()
	var out := ""
	var i := 0
	while i < s.length():
		if i == 0 or not _is_word_char(s[i - 1]):
			var m := _match_at(s, lower, i)
			if not m.is_empty():
				var shown := s.substr(i, m["length"])
				if linked.has(m["term"]):
					out += _escape(shown)
				else:
					linked[m["term"]] = true
					terms.append(m["term"])
					out += _link(m["term"], shown)
				i += m["length"]
				continue
		out += _escape(s[i])
		i += 1
	return out


## The longest glossary pattern that starts at `i` and ends on a word boundary
## (after an optional suffix): {term, length}, or {}.
static func _match_at(s: String, lower: String, i: int) -> Dictionary:
	for p in _all_patterns():
		var text: String = p["text"]
		var n := text.length()
		if i + n > s.length():
			continue
		var found: bool = s.substr(i, n) == text if p["exact"] else lower.substr(i, n) == p["lower"]
		if not found:
			continue
		for suffix in SUFFIXES:
			var end := i + n + suffix.length()
			if end <= s.length() and lower.substr(i + n, suffix.length()) == suffix \
					and (end == s.length() or not _is_word_char(s[end])):
				return {"term": p["term"], "length": end - i}
	return {}


## Every auto-linkable term and alias, longest first.
static func _all_patterns() -> Array[Dictionary]:
	if not _patterns.is_empty():
		return _patterns
	for key in Glossary.ENTRIES:
		var e: Dictionary = Glossary.ENTRIES[key]
		if e["explicit_only"]:
			continue
		var forms := PackedStringArray([key])
		forms.append_array(e["aliases"])
		for form in forms:
			var text := form
			var exact := _has_inner_capital(form)
			if not exact and form.length() > 1 and form.to_upper() in str(e["title"]).split(" "):
				text = form.to_upper()
				exact = true
			_patterns.append({"text": text, "lower": text.to_lower(), "term": key, "exact": exact})
	_patterns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["text"].length() > b["text"].length())
	return _patterns


## "mA" or "SiO₂": a capital after the first letter means the case matters.
static func _has_inner_capital(form: String) -> bool:
	for k in range(1, form.length()):
		var c := form[k]
		if c != c.to_lower():
			return true
	return false


static func _is_word_char(c: String) -> bool:
	return c.to_upper() != c.to_lower() or (c >= "0" and c <= "9")


static func _link(term: String, shown: String) -> String:
	return "[url=%s][color=%s]%s[/color][/url]" % [term, LINK_COLOR, _escape(shown)]


## A "[" in copy would start a BBCode tag; [lb] shows it as a plain bracket.
static func _escape(s: String) -> String:
	return s.replace("[", "[lb]")

all:
	markdown enumerator-traits.md > enumerator-traits-body.html
	cat header enumerator-traits-body.html footer > enumerator-traits.html


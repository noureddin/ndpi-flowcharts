all:
	git add .; git c -m"$(shell LC_ALL=C date -u '+%F %a %T')"; true
	perl mk.pl

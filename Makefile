both:
	coffee -o ./out/ -w -c ./src/*.coffee &
	python3 -m http.server 8000 -d ./out


bwatch:
	coffee -o ./out/ -w -c ./src/*.coffee &
comp/roll:
	coffee -o ./out/ -c ./src/*.coffee
	cp ./out/*.js /var/www/html/
	cp ./out/*.html /var/www/html/

out/main.js:
	coffee -o ./out/ -c ./src/*.coffee
watch:
	coffee -o ./out/ -w -c ./src/*.coffee
testo:
	yarn run test
clean:
	rm out/*.js

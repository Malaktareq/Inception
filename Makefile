all : volumes run

volumes:
	mkdir -p ~/data
	chmod +777 ~/data
	mkdir -p ~/data/wp ~/data/db
	chmod +777 ~/data/wp ~/data/db

run :
	cd srcs && docker compose up -d

clean :
	cd srcs && docker compose down -v
fclean : clean
	rm -rf ~/data
	docker rmi -f $(docker images -q)

.PHONY: clean run
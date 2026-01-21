all : volumes run

volumes:
	mkdir -p ~/data
	mkdir -p ~/data/wp ~/data/db

run :
	cd srcs && docker compose up -d --build
clean :
	cd srcs && docker compose down -v
fclean : clean
	-docker rmi -f `docker images -q`
re: fclean all
.PHONY: clean run
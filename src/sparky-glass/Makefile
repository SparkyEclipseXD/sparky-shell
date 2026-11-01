OUT := $(HOME)/.local/lib/sparky/libsparkyglass.so

$(OUT): sparky-glass.c
	gcc -shared -fPIC -O2 -Wall -o $@ $< $(shell pkg-config --cflags --libs wayland-client) -ldl
